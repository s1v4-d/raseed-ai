import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptRepository {
  ReceiptRepository({required this.uid});
  final String? uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamReceipts() {
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('receipts')
        .orderBy('purchaseDate', descending: true)
        .snapshots();
  }

  String uploadPath(String filename) {
    return 'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}_$filename';
  }

  Future<void> upload() async {
    if (uid == null) return;
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    final path = uploadPath(img.name);
    await FirebaseStorage.instance.ref(path).putData(await img.readAsBytes());
    // Storage rules ensure only matching uid can upload
  }
}
