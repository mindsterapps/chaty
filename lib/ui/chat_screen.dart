import 'dart:async';
import 'package:chaty/ui/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_list.dart';
import 'message_input.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String senderName;
  final int? intialChatLimit;
  final Widget Function(
    BuildContext context, {
    required void Function(String txt) sendMessage,
    required void Function(String mediaPath, MessageType type) sendMediaMessage,
  })? sendMessageBuilder;
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;
  final Future<String> Function(String mediaPath)? mediaUploaderFunction;
  final Function(Timestamp? lastSeen)? getLastSeen;
  final Function()? onDeleteMessage;
  const ChatScreen({
    required this.senderId,
    required this.receiverId,
    this.sendMessageBuilder,
    this.messageBubbleBuilder,
    this.mediaUploaderFunction,
    this.intialChatLimit,
    Key? key,
    this.getLastSeen,
    this.onDeleteMessage,
    required this.senderName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  Message? _lastMessage;
  bool _hasMoreMessages = true;
  late final String chatId;

  @override
  void initState() {
    _chatService.initialLimit = widget.intialChatLimit ?? 15;
    chatId = _chatService.getChatId(widget.senderId, widget.receiverId);
    super.initState();
    _fetchInitialMessages();
    _fetchlastseen();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchlastseen() async {
    final lastSeen = _chatService.updateLastSeen(widget.senderId);
    widget.getLastSeen?.call(await lastSeen);
  }

  Future<void> _fetchInitialMessages() async {
    _chatService.streamLatestMessages(chatId).listen((newMessages) {
      if (mounted) {
        setState(() {
          if (_messages.isEmpty) {
            _messages = List.from(newMessages);
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
      }
    });
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(chatId, widget.senderId);
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore.value || !_hasMoreMessages || _lastMessage == null)
      return;
    _isLoadingMore.value = true;

    List<Message> olderMessages = await _chatService.fetchMessages(
      chatId,
      lastMessage: _lastMessage,
    );

    if (olderMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(olderMessages); // Append at the end
        _lastMessage = olderMessages.last;
      });
    } else {
      _hasMoreMessages = false;
    }

    _isLoadingMore.value = false;
  }

  void _sendMessage(String text) {
    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: text,
      mediaUrl: null,
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  void _sendMediaMessage(String? mediaPath, MessageType type) async {
    if (mediaPath == null) return;
    final path = await widget.mediaUploaderFunction?.call(mediaPath);
    if (path == null) return;

    Message message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: '',
      type: type,
      mediaUrl: path,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );

    _chatService.sendMessage(message);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    double threshold =
        MediaQuery.of(context).size.height * 0.2; // 20% of screen height
    if (_scrollController.position.pixels <= threshold &&
        !_isLoadingMore.value &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  void _confirmDeleteMessage(String messageId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Message?"),
        content: Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete")),
        ],
      ),
    );

    if (confirmDelete) {
      _chatService.deleteMessage(chatId, messageId);

      setState(() {
        _messages.removeWhere((msg) => msg.messageId == messageId);
      });
      widget.onDeleteMessage?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MessageList(
              onDismiss: ({required index, required messageId}) {
                _confirmDeleteMessage(messageId);
              },
              messageBubble: ({required isMe, required message}) =>
                  widget.messageBubbleBuilder?.call(
                    message: message,
                    isMe: isMe,
                  ) ??
                  MessageBubble(
                    isMe: isMe,
                    message: message,
                  ),
              messages: _messages,
              senderId: widget.senderId,
              scrollController: _scrollController,
              isLoadingMore: _isLoadingMore.value,
            ),
          ),
          widget.sendMessageBuilder?.call(
                context,
                sendMessage: _sendMessage,
                sendMediaMessage: _sendMediaMessage,
              ) ??
              MessageInput(
                onSendMessage: _sendMessage,
                onSendAudioMessage: _sendMediaMessage,
              ),
        ],
      ),
    );
  }
}
