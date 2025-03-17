import 'dart:async';
import 'package:chaty/ui/message_bubble.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_list.dart';
import 'message_input.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final int? intialChatLimit;
  final Widget Function(
    BuildContext context, {
    required void Function(String txt) sendMessage,
    required void Function(String audioPath) sendAudioMessage,
  })? sendMessageBuilder;
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;
  final Future<String> Function(String mediaPath)? mediaUploaderFunction;
  const ChatScreen({
    required this.senderId,
    required this.receiverId,
    this.sendMessageBuilder,
    this.messageBubbleBuilder,
    this.mediaUploaderFunction,
    this.intialChatLimit,
    Key? key,
  }) : super(key: key);

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
  late final String chatId;

  @override
  void initState() {
    _chatService.initialLimit = widget.intialChatLimit ?? 5;
    chatId = _chatService.getChatId(widget.senderId, widget.receiverId);
    super.initState();
    _fetchInitialMessages();
    _markMessagesAsRead();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchInitialMessages() async {
    _chatService.streamLatestMessages(chatId).listen((newMessages) {
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
    _chatService.markMessagesAsRead(chatId, widget.senderId);
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

  void _sendAudioMessage(String? audioPath) async {
    if (audioPath == null) return;
    final path = await widget.mediaUploaderFunction?.call(audioPath);
    if (path == null) return;
    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: '',
      mediaUrl: path,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  void _onScroll() {
    double threshold = 5.0;
    if (_scrollController.position.pixels <= threshold &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MessageList(
            messageBubble: ({required isMe, required message}) => MessageBubble(
              isMe: isMe,
              message: message,
            ),
            messages: _messages,
            senderId: widget.senderId,
            scrollController: _scrollController,
            isLoadingMore: _isLoadingMore,
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          widget.sendMessageBuilder?.call(
                context,
                sendMessage: _sendMessage,
                sendAudioMessage: _sendAudioMessage,
              ) ??
              MessageInput(
                onSendMessage: _sendMessage,
                onSendAudioMessage: _sendAudioMessage,
              ),
        ],
      ),
    );
  }
}
