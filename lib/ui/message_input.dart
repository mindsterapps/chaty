import 'package:chaty/models/message.dart';
import 'package:chaty/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendMessage;
  final Function(String? audioPath, MessageType type) onSendAudioMessage;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.onSendAudioMessage,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      "❌ Microphone permission not granted".log();
      return;
    }

    await _audioRecorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _audioPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder!.startRecorder(toFile: _audioPath);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() => _isRecording = false);
    widget.onSendAudioMessage(_audioPath, MessageType.voice);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    widget.onSendMessage(_messageController.text.trim());
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
          IconButton(
            icon:
                Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.red),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
        ],
      ),
    );
  }
}
