import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../widgets/receipt_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: Text('Sign in required'));
    // stream receipts
    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      body: const ReceiptList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(receiptRepoProvider).upload(),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
