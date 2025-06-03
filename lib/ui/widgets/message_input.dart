import 'package:chaty/models/message.dart';
import 'package:chaty/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// A widget for composing and sending text or audio messages in a chat.
///
/// Provides a text input field, send button, and audio recording functionality.
class MessageInput extends StatefulWidget {
  /// Callback when a text message is sent.
  final Function(String text) onSendMessage;

  /// Callback when an audio message is sent. The [audioPath] may be null if recording failed.
  final Function(String? audioPath, MessageType type) onSendAudioMessage;

  /// Creates a [MessageInput] widget.
  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.onSendAudioMessage,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

/// State for [MessageInput], manages text input, audio recording, and sending messages.
class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      "❌ Microphone permission not granted".log();
      return;
    }
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _audioPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
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
