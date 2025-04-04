import 'dart:async';

import 'package:chaty/services/chat_service.dart';
import 'package:chaty/ui/message_bubble.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessageList extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final int initialChatLimit;
  final Function(DateTime lastSeen)? getLastSeen;
  final Function()? onDeleteMessage;
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;

  const ChatMessageList({
    required this.senderId,
    required this.receiverId,
    this.initialChatLimit = 15,
    this.getLastSeen,
    this.onDeleteMessage,
    this.messageBubbleBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ChatService _chatService = ChatService.instance;
  final ScrollController _scrollController = ScrollController();
  late final ValueNotifier<List<Message>> _messages = ValueNotifier([]);

  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  Message? _lastMessage;
  bool _hasMoreMessages = true;
  late final String chatId;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    chatId = _chatService.getChatId(widget.senderId, widget.receiverId);
    _chatService.initialLimit = widget.initialChatLimit;
    _chatService.updateLastSeen(widget.senderId);
    _fetchLastSeen();
    _scrollController.addListener(_onScroll);
    _listenToMessages();
    super.initState();
  }

  void _listenToMessages() {
    _messageSub =
        _chatService.streamLatestMessages(chatId).listen((newMessages) {
      if (!mounted) return;
      setState(() {
        for (var msg in newMessages) {
          if (!_messages.value.any((m) => m.messageId == msg.messageId)) {
            _messages.value.insert(0, msg);
            _messages.notifyListeners();
          }
        }
        if (_messages.value.isNotEmpty) {
          _lastMessage = _messages.value.last;
        }
      });
      _chatService.markMessagesAsRead(chatId, widget.senderId);
    });
  }

  void _fetchLastSeen() {
    _chatService.getLastSeen(widget.receiverId).listen((event) {
      if (event != null) {
        widget.getLastSeen?.call(event.toDate());
      }
    });
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
        _messages.value.addAll(olderMessages);
        _lastMessage = olderMessages.last;
        _messages.notifyListeners();
      });
    } else {
      _hasMoreMessages = false;
    }

    _isLoadingMore.value = false;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    double threshold = MediaQuery.of(context).size.height * 0.2;
    if (_scrollController.position.pixels <= threshold &&
        !_isLoadingMore.value &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  void _confirmDeleteMessage(String messageId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm) {
      await _chatService.deleteMessage(chatId, messageId);
      setState(() {
        _messages.value.removeWhere((msg) => msg.messageId == messageId);
      });
      widget.onDeleteMessage?.call();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<Message>>(
          valueListenable: _messages,
          builder: (context, messages, _) {
            return ListView.builder(
              cacheExtent: 10000,
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.value.length,
              itemBuilder: (context, index) {
                final message = _messages.value[index];
                return KeyedSubtree(
                  key: ValueKey(message.messageId),
                  child: GestureDetector(
                    onLongPress: () => _confirmDeleteMessage(message.messageId),
                    child: widget.messageBubbleBuilder?.call(
                          message: message,
                          isMe: message.senderId == widget.senderId,
                        ) ??
                        MessageBubble(
                            isMe: message.senderId == widget.senderId,
                            message: message),
                  ),
                );
              },
            );
          }),
    );
  }
}
