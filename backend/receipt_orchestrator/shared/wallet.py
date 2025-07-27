import json
import logging
import os
import time
from typing import Dict
import google.auth
from google.oauth2 import service_account
from google.auth import impersonated_credentials
from google.cloud import secretmanager
from googleapiclient.discovery import build

_WALLET_SCOPE = ["https://www.googleapis.com/auth/wallet_object.issuer"]
_WALLET_BASE_URL = "https://walletobjects.googleapis.com/walletobjects/v1"
_ISSUER_ID = os.getenv("GOOGLE_WALLET_ISSUER_ID")
_CLASS_ID = f"{_ISSUER_ID}.receipt_class"
_PROJECT_ID = os.getenv("PROJECT_ID")

def _get_wallet_service_account_email():
    """Get the wallet service account email from Secret Manager."""
    client = secretmanager.SecretManagerServiceClient()
    secret_name = f"projects/{_PROJECT_ID}/secrets/wallet-issuer-email/versions/latest"
    response = client.access_secret_version(request={"name": secret_name})
    return response.payload.data.decode("UTF-8")

def _wallet_client():
    """Create wallet API client using service account impersonation."""
    # Get the service account email from Secret Manager
    target_sa_email = _get_wallet_service_account_email()
    
    # Create impersonated credentials
    source_credentials, _ = google.auth.default()
    target_credentials = impersonated_credentials.Credentials(
        source_credentials=source_credentials,
        target_principal=target_sa_email,
        target_scopes=_WALLET_SCOPE,
        delegates=[]
    )
    
    return build("walletobjects", "v1", credentials=target_credentials, cache_discovery=False)

def ensure_class():
    """Idempotently create a GenericPass class."""
    service = _wallet_client()
    try:
        service.genericclass().get(resourceId=_CLASS_ID).execute()
        return
    except Exception:
        # 404 –> create
        body = {
            "id": _CLASS_ID,
            "issuerName": "Raseed",
            "classTemplateInfo": {
                "cardTemplateOverride": {
                    "cardRowTemplateInfos": [
                        {"twoItems": {"startItem": "totalPrice", "endItem": "purchaseDate"}}
                    ]
                }
            },
        }
        service.genericclass().insert(body=body).execute()

def create_receipt_object(data: Dict) -> str:
    """
    Build a GenericPass object and return a signed JWT for Add‑to‑Wallet.
    `data` must include: id, vendorName, purchaseDate, totalPrice, lineItems, category, locale.
    """
    ensure_class()
    object_id = f"{_ISSUER_ID}.{data['id']}"
    payload = {
        "iss": _ISSUER_ID,
        "aud": "google",
        "typ": "savetoandroidpay",
        "iat": int(time.time()),
        "payload": {
            "genericObjects": [
                {
                    "id": object_id,
                    "classId": _CLASS_ID,
                    "state": "ACTIVE",
                    "heroImage": {
                        "sourceUri": {"uri": "https://example.com/hero.png", "description": "Receipt"}
                    },
                    "textModulesData": [
                        {"header": "Vendor", "body": data["vendorName"]},
                        {"header": "Total", "body": data["totalPrice"]},
                    ],
                    "linksModuleData": {
                        "uris": [{"uri": data.get("deepLink", "raseed://receipt/" + data["id"])}]
                    },
                    "infoModuleData": {
                        "labelValueRows": [
                            {"columns": [{"label": "Date", "value": data["purchaseDate"]}]},
                            {"columns": [{"label": "Category", "value": data["category"]}]},
                        ]
                    },
                    "barcode": {"type": "QR_CODE", "value": object_id},
                    "hexBackgroundColor": "#4285F4",
                    "logo": {
                        "sourceUri": {"uri": "https://example.com/logo.png", "description": "Raseed"}
                    },
                }
            ]
        },
    }
    
    # Get the service account email and create impersonated credentials for JWT signing
    target_sa_email = _get_wallet_service_account_email()
    source_credentials, _ = google.auth.default()
    target_credentials = impersonated_credentials.Credentials(
        source_credentials=source_credentials,
        target_principal=target_sa_email,
        target_scopes=_WALLET_SCOPE,
        delegates=[]
    )
    
    # Sign the JWT using impersonated credentials
    jwt = target_credentials.with_claims(extra_claims=payload).token
    return jwt
