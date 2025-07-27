import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/receipt_repo.dart';
import 'services/chat_service.dart';

// Stream<User?> – emits on login / logout
final authStateProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

// Helper repo providers so they can read the uid
final receiptRepoProvider = Provider<ReceiptRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  return ReceiptRepository(uid: user?.uid);
});

final chatServiceProvider = Provider<ChatService>((ref) {
  final user = ref.watch(authStateProvider).value;
  return ChatService(uid: user?.uid);
});
