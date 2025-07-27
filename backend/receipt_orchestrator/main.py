import functions_framework
from google.cloud import storage
from agent import receipt_agent

@functions_framework.cloud_event
def on_gcs_finalise(event):
    data = event.data
    user_id = data["metadata"].get("firebaseUserId", "anon")
    gcs_uri = f"gs://{data['bucket']}/{data['name']}"
    receipt_agent.run(user_id=user_id, gcs_uri=gcs_uri)
