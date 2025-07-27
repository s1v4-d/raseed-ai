from google.adk.agents import LlmAgent
from google.adk.tools import FunctionTool, GoogleSearchTool
from google.cloud import firestore, aiplatform
from google.cloud.aiplatform_v1 import MatchServiceClient
from firebase_admin import auth
import textwrap, base64, os, logging
import vertexai
from vertexai.language_models import TextEmbeddingModel, TextEmbeddingInput

# Initialize Vertex AI
PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT")
REGION = os.getenv("REGION", "us-central1")
vertexai.init(project=PROJECT, location=REGION)

_firestore = firestore.Client()
_llm = aiplatform.GenerativeModel("gemini-2.5-flash")

def verify_token(id_token: str) -> str:
    return auth.verify_id_token(id_token)["uid"]

def receipt_search(query: str, uid: str) -> str:
    embed_model = TextEmbeddingModel.from_pretrained("gemini-embedding-001")
    inputs = [TextEmbeddingInput(query, "RETRIEVAL_QUERY")]
    embeddings = embed_model.get_embeddings(inputs)
    vec = embeddings[0].values
    
    try:
        # Use the deployed index endpoint for search
        PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT")
        REGION = os.getenv("REGION", "us-central1")
        endpoint_ids = ["14181500975054848"]  # Use the existing deployed endpoint
        
        for endpoint_id in endpoint_ids:
            try:
                # Create match service client for querying the deployed index
                match_client = MatchServiceClient()
                endpoint_path = f"projects/{PROJECT}/locations/{REGION}/indexEndpoints/{endpoint_id}"
                
                # Query the deployed index
                request = {
                    "index_endpoint": endpoint_path,
                    "deployed_index_id": "receipts_index_v1",  # From Terraform config
                    "queries": [{
                        "query_embedding": vec,
                        "neighbor_count": 5
                    }]
                }
                
                response = match_client.match_embeddings(**request)
                
                summaries = []
                if response.match_results:
                    for neighbor in response.match_results[0].neighbors:
                        receipt_id = neighbor.datapoint_id
                        distance = neighbor.distance
                        
                        # Get receipt details from Firestore
                        doc = (
                            _firestore.collection("users")
                            .document(uid)
                            .collection("receipts")
                            .document(receipt_id)
                            .get()
                            .to_dict()
                        )
                        if doc:
                            summaries.append({
                                "id": receipt_id, 
                                "vendor": doc.get("vendor"), 
                                "total": doc.get("totalPrice"),
                                "distance": distance
                            })
                
                return textwrap.shorten(str(summaries), 150) if summaries else "No matching receipts found"
                
            except Exception as e:
                print(f"Failed to search with endpoint {endpoint_id}: {e}")
                continue
                
        return "Vector search not available - no valid index endpoints found"
            
    except Exception as e:
        print(f"Warning: Could not perform vector search: {e}")
        return f"Vector search failed: {str(e)}"

def translate_back(text, lang):
    return text

chat_agent = LlmAgent(
    name="RaseedChat",
    model="gemini-2.0-flash",
    instruction="You are Raseed, a helpful finance assistant.",
    tools=[
        FunctionTool("ReceiptSearch", receipt_search),
        GoogleSearchTool(),
    ],
)
