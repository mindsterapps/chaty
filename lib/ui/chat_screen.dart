import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_list.dart';
import 'message_input.dart';

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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoadingMore = false;
  Message? _lastMessage;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialMessages();
    _markMessagesAsRead();
  }

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
          _lastMessage = _messages.last;
        }
      });
      _markMessagesAsRead();
    });
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.chatId, widget.senderId);
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _lastMessage == null) return;
    setState(() => _isLoadingMore = true);

    List<Message> olderMessages = await _chatService.fetchMessages(
        _chatService.getChatId(widget.senderId, widget.receiverId),
        lastMessage: _lastMessage);
    if (olderMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(olderMessages);
        _lastMessage = olderMessages.last;
      });
    } else {
      setState(() => _hasMoreMessages = false);
    }

    setState(() => _isLoadingMore = false);
  }

  void _sendMessage(String text) {
    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: text,
      mediaUrl: null,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  void _sendAudioMessage(String? audioPath) {
    if (audioPath == null) return;

    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: '',
      mediaUrl: audioPath,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      floatingActionButton: FloatingActionButton(onPressed: _loadMoreMessages),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Column(
        children: [
          MessageList(
            messages: _messages,
            senderId: widget.senderId,
            scrollController: _scrollController,
            isLoadingMore: _isLoadingMore,
          ),
          MessageInput(
            onSendMessage: _sendMessage,
            onSendAudioMessage: _sendAudioMessage,
          ),
        ],
      ),
    );
  }
}
