import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceHelper {
  final _rec = Record();

  Future<File?> recordOnce({Duration max = const Duration(seconds: 15)}) async {
    if (!await _rec.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _rec.start(
      path: file.path,
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
    );
    await Future.delayed(max);
    final path = await _rec.stop();
    return path == null ? null : File(path);
  }
}
