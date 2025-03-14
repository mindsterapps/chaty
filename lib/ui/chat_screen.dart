import 'dart:async';
import 'package:chaty/utils/extensions.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_bubble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;
  final Widget Function(bool isMe, Message message)? chatBubble;
  final Widget Function(Function? onSend)? sendMessagebottom;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    this.chatBubble,
    this.sendMessagebottom,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoadingMore = false;
  Message? _lastMessage;
  bool _hasMoreMessages = true;

  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _fetchInitialMessages();
    _markMessagesAsRead();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ("❌ Microphone permission not granted").log('#AudioRecorder');
      return;
    }

    await _audioRecorder!.openRecorder();
  }

  /// Start recording audio
  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _audioPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder!.startRecorder(toFile: _audioPath);
    setState(() => _isRecording = true);
  }

  /// Stop recording audio
  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() => _isRecording = false);
    _sendAudioMessage();
  }

  /// Send an audio message
  void _sendAudioMessage() {
    if (_audioPath == null) return;

    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: '',
      mediaUrl: _audioPath,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  /// Fetch the first batch of messages with real-time updates
  Future<void> _fetchInitialMessages() async {
    _chatService.streamLatestMessages(widget.chatId).listen((newMessages) {
      setState(() {
        if (_messages.isEmpty) {
          _messages = newMessages;
        } else {
          for (var msg in newMessages) {
            if (!_messages.any((m) => m.messageId == msg.messageId)) {
              _messages.insert(0, msg);
            }
          }
        }
        if (_messages.isNotEmpty) {
          _lastMessage = _messages.last; // Save last message for pagination
        }
      });
      _markMessagesAsRead();
    });
  }

  /// Mark all messages as read
  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.chatId, widget.senderId);
  }

  /// Load older messages when pulling down
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _lastMessage == null) return;
    setState(() => _isLoadingMore = true);

    List<Message> olderMessages = await _chatService.fetchMessages(
        _chatService.getChatId(widget.senderId, widget.receiverId),
        lastMessage: _lastMessage);
    if (olderMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(olderMessages);
        _lastMessage = olderMessages.last; // Update last message for pagination
      });
    } else {
      setState(() => _hasMoreMessages = false); // No more messages to load
    }

    setState(() => _isLoadingMore = false);
  }

  /// Send a message
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: _messageController.text.trim(),
      mediaUrl: null,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      floatingActionButton: FloatingActionButton(onPressed: _loadMoreMessages),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final bubble = widget.chatBubble?.call(
                    _messages[index].senderId == widget.senderId,
                    _messages[index]);
                return bubble ??
                    MessageBubble(
                      message: _messages[index],
                      isMe: _messages[index].senderId == widget.senderId,
                    );
              },
            ),
          ),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                      color: Colors.red),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                MessageTextField(messageController: _messageController),
                widget.sendMessagebottom?.call(_sendMessage) ??
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageTextField extends StatelessWidget {
  const MessageTextField({
    super.key,
    required TextEditingController messageController,
  }) : _messageController = messageController;

  final TextEditingController _messageController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: _messageController,
        decoration: const InputDecoration(
          hintText: "Type a message...",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
