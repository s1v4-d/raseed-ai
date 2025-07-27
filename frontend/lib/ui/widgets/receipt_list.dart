import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import 'wallet_button.dart';

class ReceiptList extends ConsumerWidget {
  const ReceiptList({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final stream = ref.watch(receiptRepoProvider).streamReceipts();
    return StreamBuilder(
      stream: stream,
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No receipts yet'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final r = docs[i].data();
            return ListTile(
              title: Text(r['vendor'] ?? 'Receipt'),
              subtitle: Text('₹${r['totalPrice'] ?? '—'} · ${r['purchaseDate']}'),
              trailing: WalletButton(jwt: r['walletJwt']),
            );
          },
        );
      },
    );
  }
}
