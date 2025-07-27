import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raseed/ui/widgets/receipt_list.dart';
import 'package:raseed/providers.dart';

class MockStream extends Mock implements Stream<QuerySnapshot<Map<String, dynamic>>> {}

void main() {
  testWidgets('Shows placeholder when no receipts', (tester) async {
    final mock = Stream<QuerySnapshot<Map<String, dynamic>>>.value(
      QuerySnapshot<Map<String, dynamic>>([], [], [], false, null, null),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receiptRepoProvider.overrideWithValue(
            FakeReceiptRepo(mock),
          ),
        ],
        child: const MaterialApp(home: ReceiptList()),
      ),
    );
    expect(find.text('No receipts yet'), findsOneWidget);
  });
}

class FakeReceiptRepo implements ReceiptRepository {
  FakeReceiptRepo(this._stream);
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReceipts() => _stream;
}
