import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../services/voice_helper.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _messages = <Map<String, String>>[]; // [{role,text}]
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final chat = ref.read(chatServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: _messages.reversed
                  .map((m) => ListTile(
                        title: Text(m['text']!, style: TextStyle(
                          color: m['role'] == 'user' ? Colors.blue : Colors.black)),
                      ))
                  .toList(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _ctrl, decoration: const InputDecoration(
                  hintText: 'Ask something…')),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_ctrl.text.trim().isEmpty) return;
                  final q = _ctrl.text.trim();
                  setState(() {
                    _messages.add({'role': 'user', 'text': q});
                    _loading = true;
                  });
                  _ctrl.clear();
                  final a = await chat.ask(q);
                  setState(() {
                    _messages.add({'role': 'assistant', 'text': a});
                    _loading = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () async {
                  final recorder = VoiceHelper();
                  final file = await recorder.recordOnce();
                  if (file == null) return;
                  setState(() => _loading = true);
                  final a = await chat.askVoice(file);
                  setState(() {
                    _messages.add({'role': 'assistant', 'text': a});
                    _loading = false;
                  });
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
