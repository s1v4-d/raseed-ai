**Google Wallet** - Digital solution for storing cards and passes 

**Frontend**
*   **State Management**: Flutter Riverpod
*   **Authentication**: Firebase Authentication
*   **Hosting**: Firebase Hosting
*   **Audio**: `record` for microphone input and `just_audio` for playback.
*   **Wallet Integration**: `google_wallet` plugin.


**Backend/Cloud functions Orchestration**
*   **Language**: Python
*   **Framework**: Cloud Functions (2nd Gen) using the Python ADK for orchestration.
*   **Microservices**:
    *   `receipt-orchestrator`: Event-driven service for processing receipts.
    *   `chat-assistant`: HTTP-triggered service for handling user queries.


**Core Compute & Storage:**
*   **Cloud Functions**: Used for the backend logic, including the `receipt-orchestrator` and `chat-assistant`.
*   **Cloud Storage**: Used for storing user-uploaded receipts (`infra/modules/storage/main.tf`), Vertex AI index data (`infra/modules/vertex_ai/main.tf`), and Cloud Functions source code (`infra/modules/cloud_functions/main.tf`).
*   **Firestore**: Used as the primary database for storing receipt data and user information (`infra/modules/firestore/main.tf`).
*   **Cloud Run**: Underpins the 2nd generation Cloud Functions.

**AI & Machine Learning (Vertex AI):**
*   **Vertex AI Platform**: The central platform for ML services.
*   **Gemini Models**: Used for AI-powered analysis and chat capabilities (`backend/chat_assistant/agent.py`).
*   **Vertex AI Matching Engine**: For finding similar items via vector search (`infra/modules/vertex_ai/main.tf`).
*   **Vertex AI Embeddings**: To create vector representations of receipt data for analysis (`backend/receipt_orchestrator/agent.py`).
*   **Cloud Vision API**: For performing OCR to extract text from receipt images.
*   **Cloud Translation API**: To translate receipt text if it's not in English.
*   **Speech-to-Text API**: Mentioned as a capability in the architecture.
*   **Text-to-Speech API**: Mentioned as a capability in the architecture.

**Application & User Facing:**
*   **Firebase Hosting**: To host the Flutter web application (`infra/modules/firebase/main.tf`).
*   **Firebase Authentication**: Manages user sign-up and login (`frontend/lib/providers.dart`).
*   **Google Wallet API**: To create and manage digital passes for receipts and financial insights (`infra/modules/wallet/main.tf`).

**Operational & Security:**
*   **Identity and Access Management (IAM)**: Manages permissions for all service accounts and resources.
*   **Secret Manager**: Used to securely store secrets like the Wallet service account email (`infra/modules/wallet/main.tf`).
*   **Cloud Build**: Used for building and deploying services.
*   **Eventarc**: Manages event-driven triggers, like the one that starts the receipt orchestrator when a file is uploaded to Cloud Storage (`infra/modules/cloud_functions/main.tf`).
*   **Pub/Sub**: Works with Eventarc to handle asynchronous messaging for event triggers.
*   **Cloud Monitoring**: Mentioned in the design documents for logging, metrics, and alerts.
*   **Cloud Resource Manager**: Manages the GCP project itself.

