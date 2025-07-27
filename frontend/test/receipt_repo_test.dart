import 'package:flutter_test/flutter_test.dart';
import 'package:raseed/services/receipt_repo.dart';

void main() {
  test('Path contains uid', () async {
    final repo = ReceiptRepository(uid: 'abc123');
    final paths = repo.uploadPath('img.jpg');
    expect(paths, contains('receipts/abc123/'));
  });
}
