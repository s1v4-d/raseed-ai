import base64
import logging
import os
from google.cloud import storage, firestore, aiplatform, vision_v1, translate_v2
from google.cloud.aiplatform_v1 import IndexServiceClient, IndexDatapoint
from google.adk.agents import SequentialAgent, LlmAgent
from google.adk.tools import FunctionTool
from google.adk import types  # Add missing import for GenerateContentConfig
from shared.wallet import create_receipt_object
from uuid import uuid4
import json
import vertexai
from vertexai.language_models import TextEmbeddingModel, TextEmbeddingInput
import requests  # For metadata service

# Ensure PROJECT is set properly - Cloud Functions should have this automatically
PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCP_PROJECT")
if not PROJECT:
    # Try to get from metadata service (available in Cloud Functions)
    try:
        metadata_url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
        headers = {"Metadata-Flavor": "Google"}
        response = requests.get(metadata_url, headers=headers, timeout=5)
        if response.status_code == 200:
            PROJECT = response.text
            print(f"Retrieved project ID from metadata: {PROJECT}")
    except Exception as e:
        print(f"Could not retrieve project ID from metadata: {e}")
        PROJECT = "raseed-test-467110"  # Fallback to known project ID

REGION = os.getenv("REGION", "us-central1")
BUCKET = os.getenv("RECEIPT_BUCKET")

# Initialize Vertex AI
if PROJECT:
    vertexai.init(project=PROJECT, location=REGION)
    print(f"Initialized Vertex AI with project: {PROJECT}")
else:
    print("Warning: No project ID available, skipping Vertex AI initialization")

_vision = vision_v1.ImageAnnotatorClient()
_translate = translate_v2.Client()
_firestore = firestore.Client()
_storage = storage.Client()

# Initialize embedding model - this will be done lazily to avoid startup issues
_embedding_model = None

def get_embedding_model():
    global _embedding_model
    if _embedding_model is None and PROJECT:
        try:
            _embedding_model = TextEmbeddingModel.from_pretrained("gemini-embedding-001")
            print("Successfully initialized gemini-embedding-001 model")
        except Exception as e:
            print(f"Warning: Could not initialize embedding model: {e}")
            # Fallback to older model
            try:
                _embedding_model = TextEmbeddingModel.from_pretrained("text-embedding-004")
                print("Fallback: Using text-embedding-004 model")
            except Exception as e2:
                print(f"Error: Could not initialize any embedding model: {e2}")
                _embedding_model = None
    return _embedding_model

# Index client and endpoint will be initialized lazily
_index_client = None
_index_name = None

def get_index_client_and_name():
    global _index_client, _index_name
    if _index_client is None and PROJECT:
        try:
            REGION = os.getenv("REGION", "us-central1")
            _index_client = IndexServiceClient()
            
            # Get index name from the index ID that was created by Terraform
            # This can be made configurable via environment variable later
            index_ids = ["4824923104495009792"]  # From the Terraform output
            
            for index_id in index_ids:
                try:
                    _index_name = f"projects/{PROJECT}/locations/{REGION}/indexes/{index_id}"
                    print(f"Using index: {_index_name}")
                    break
                except Exception as e:
                    print(f"Failed to use index {index_id}: {e}")
                    continue
                    
            if _index_name is None:
                print("Warning: Could not initialize any index")
                
        except Exception as e:
            print(f"Warning: Could not initialize index client: {e}")
            _index_client = None
            _index_name = None
    return _index_client, _index_name

def ingest_file(user_id: str, gcs_uri: str) -> dict:
    receipt_id = uuid4().hex
    return {"receipt_id": receipt_id, "gcs_uri": gcs_uri, "user_id": user_id}

def run_ocr(gcs_uri: str, **kw) -> dict:
    image = vision_v1.Image(source=vision_v1.ImageSource(gcs_image_uri=gcs_uri))
    res = _vision.document_text_detection(image=image)
    text = res.full_text_annotation.text
    return {"text": text}

def translate(text: str, **kw) -> dict:
    result = _translate.translate(text, target_language="en")
    return {"text_en": result["translatedText"], "source_lang": result["detectedSourceLanguage"]}

def embed(text_en: str, receipt_id: str, **kw) -> dict:
    embedding_model = get_embedding_model()
    if embedding_model is None:
        print("Warning: No embedding model available, skipping embedding")
        return {"embedding": False, "error": "No embedding model available"}
    
    try:
        # Create TextEmbeddingInput with the text and task type
        inputs = [TextEmbeddingInput(text_en, "RETRIEVAL_DOCUMENT")]
        embeddings = embedding_model.get_embeddings(inputs)
        vec = embeddings[0].values
        
        # Try to upsert to index using the new streaming API
        index_client, index_name = get_index_client_and_name()
        if index_client is not None and index_name is not None:
            try:
                # Create IndexDatapoint for streaming upsert
                datapoint = IndexDatapoint(
                    datapoint_id=receipt_id,
                    feature_vector=vec,
                    restricts=[
                        IndexDatapoint.Restriction(
                            namespace="category", 
                            allow=["receipt"]
                        )
                    ]
                )
                
                # Upsert to the index (not endpoint)
                index_client.upsert_datapoints(
                    index=index_name,
                    datapoints=[datapoint]
                )
                print(f"Successfully upserted embedding for receipt {receipt_id}")
                return {"embedding": True}
            except Exception as e:
                print(f"Warning: Could not upsert to index: {e}")
                return {"embedding": False, "error": f"Index upsert failed: {str(e)}"}
        else:
            print("Warning: Index not available, skipping vector upsert")
            return {"embedding": False, "error": "Index not available"}
    except Exception as e:
        print(f"Error during embedding: {e}")
        return {"embedding": False, "error": f"Embedding failed: {str(e)}"}

def persist(user_id: str, receipt_id: str, **values) -> dict:
    doc_ref = _firestore.collection("users").document(user_id).collection("receipts").document(receipt_id)
    doc_ref.set({**values, "status": "processing"})
    return {"firestore_doc": doc_ref.path}

def wallet_pass(receipt_id: str, text_en: str, **values) -> dict:
    vendor = text_en.split("\n")[0][:50]
    jwt = create_receipt_object(
        {
            "id": receipt_id,
            "vendorName": vendor,
            "purchaseDate": values.get("purchaseDate", "TBD"),
            "totalPrice": values.get("totalPrice", "TBD"),
            "category": values.get("category", "uncategorised"),
            "lineItems": text_en,
        }
    )
    doc = _firestore.document(values["firestore_doc"])
    doc.update({"walletJwt": jwt, "status": "completed"})
    return {"jwt": jwt}

# Create LlmAgent instances that use the FunctionTool objects in their tools list
ingest_agent = LlmAgent(
    name="IngestAgent",
    model="gemini-2.0-flash",
    instruction="Process file ingestion for receipt using the ingest_file tool",
    tools=[FunctionTool(func=ingest_file)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

ocr_agent = LlmAgent(
    name="OCRAgent", 
    model="gemini-2.0-flash",
    instruction="Extract text from receipt image using the run_ocr tool",
    tools=[FunctionTool(func=run_ocr)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

translate_agent = LlmAgent(
    name="TranslateAgent",
    model="gemini-2.0-flash", 
    instruction="Translate receipt text to English using the translate tool",
    tools=[FunctionTool(func=translate)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

embed_agent = LlmAgent(
    name="EmbedAgent",
    model="gemini-2.0-flash",
    instruction="Generate embeddings for receipt text using the embed tool",
    tools=[FunctionTool(func=embed)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

persist_agent = LlmAgent(
    name="PersistAgent",
    model="gemini-2.0-flash",
    instruction="Store receipt data in Firestore using the persist tool",
    tools=[FunctionTool(func=persist)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

wallet_agent = LlmAgent(
    name="WalletAgent",
    model="gemini-2.0-flash",
    instruction="Create Google Wallet pass for receipt using the wallet_pass tool",
    tools=[FunctionTool(func=wallet_pass)],
    generate_content_config=types.GenerateContentConfig(temperature=0.0)
)

receipt_agent = SequentialAgent(
    name="ReceiptPipeline",
    sub_agents=[
        ingest_agent,
        ocr_agent,
        translate_agent,
        embed_agent,
        persist_agent,
        wallet_agent,
    ],
)
