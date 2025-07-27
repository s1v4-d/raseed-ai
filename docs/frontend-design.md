# Frontend Design

## Folder Structure
- Feature-based: `lib/core/`, `lib/models/`, `lib/services/`, `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/blocs/`, `lib/l10n/`
- Responsive via `LayoutBuilder` for web/mobile
- Wallet integration via `google_wallet` plugin
- Real-time UI via Firestore streams
- State management: Riverpod/BLoC

## Auth & User Management
- Firebase Auth (email, Google, etc.)
- ID token attached to all backend calls
- User state exposed as `Stream<User?>` via provider

## Receipt Upload & List
- Uploads to `receipts/{uid}/...` in Storage
- Listens to Firestore for real-time updates
- “Add to Wallet” button uses JWT from backend

## Chat UI
- StreamBuilder for chat messages
- Calls `/api/chat` (text) or `/api/chat/voice` (voice)
- Handles both text and TTS audio responses

## Voice Support
The web build captures up to 15 s of microphone audio via the [`record`](https://pub.dev/packages/record) plugin and posts raw bytes to `/api/chat/voice`. The backend returns both a text answer and a signed URL for synthesized speech, which is played with [`just_audio`](https://pub.dev/packages/just_audio). For unit tests of voice, mock `AudioPlayer` instances.

## Testing
- Unit tests for services
- Widget tests for UI

See [README.md](../README.md) and [backend-design.md](backend-design.md) for more.
