import 'dart:async';
import 'dart:io';
import 'package:chaty/services/chat_services.dart';
import 'package:chaty/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _receiverTyping = false;

  @override
  void initState() {
    super.initState();
    print(
        'widget.chatid: ${widget.chatId}\nwidget.senderId: ${widget.senderId}\nwidget.receiverId ${widget.receiverId}');

    _chatService.markMessagesAsRead(widget.chatId, widget.senderId);
    _chatService.getTypingStatus(widget.chatId).listen((status) {
      if (status != null) {
        setState(() {
          _receiverTyping = status[widget.receiverId] ?? false;
        });
      }
    });
  }

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
    _chatService.updateTypingStatus(widget.chatId, widget.senderId, false);
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _selectedImage = File(pickedFile.path));

    String? mediaUrl = await _storageService.uploadMedia(
        File(pickedFile.path), 'chat_media/${widget.senderId}');
    if (mediaUrl != null) {
      Message message = Message(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        text: "",
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
        status: MessageStatus.unread,
      );

      _chatService.sendMessage(message);
    }
  }

  void _onTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _chatService.updateTypingStatus(widget.chatId, widget.senderId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _chatService.updateTypingStatus(widget.chatId, widget.senderId, false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Visibility(
            visible: _receiverTyping,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Typing...",
                style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<Message> messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: messages[index],
                      isMe: messages[index].senderId == widget.senderId,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5.0),
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[50],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (_) => _onTyping(),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
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
