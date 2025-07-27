import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  ChatService({required this.uid});
  final String? uid;

  Future<String> ask(String prompt) async {
    if (uid == null) return 'Please sign in first.';
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.post(
      Uri.parse('/api/chat'), // Hosting rewrite
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'message': prompt}),
    );
    return jsonDecode(res.body)['answer'] as String;
  }

  Future<String> askVoice(File audio) async {
    if (uid == null) return 'Sign‑in required.';
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final bytes = await audio.readAsBytes();
    final res = await http.post(
      Uri.parse('/api/chat/voice'),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Authorization': 'Bearer $token'
      },
      body: bytes,
    );
    final json = jsonDecode(res.body);
    if (json['audioUrl'] != null) {
      // Optionally play audio with just_audio
      // final player = AudioPlayer();
      // await player.setUrl(json['audioUrl']);
      // player.play();
    }
    return json['answer'];
  }
}
