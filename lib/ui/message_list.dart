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
  List<Message> _messages = [];
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
          if (!_messages.any((m) => m.messageId == msg.messageId)) {
            _messages.insert(0, msg);
          }
        }
        if (_messages.isNotEmpty) {
          _lastMessage = _messages.last;
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
        _messages.addAll(olderMessages);
        _lastMessage = olderMessages.last;
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
        _messages.removeWhere((msg) => msg.messageId == messageId);
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
    return MessageList(
      messages: _messages,
      senderId: widget.senderId,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore.value,
      messageBubble: ({required isMe, required message}) =>
          widget.messageBubbleBuilder?.call(
            message: message,
            isMe: isMe,
          ) ??
          MessageBubble(isMe: isMe, message: message),
      onDismiss: ({required index, required messageId}) {
        _confirmDeleteMessage(messageId);
      },
    );
  }
}

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String senderId;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final void Function({required String messageId, required int index})
      onDismiss;
  final Widget Function({required Message message, required bool isMe})
      messageBubble;
  const MessageList({
    Key? key,
    required this.messages,
    required this.senderId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.messageBubble,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        cacheExtent: 10000,
        controller: scrollController,
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _Tile(
              onLongPress: () {
                onDismiss(messageId: message.messageId, index: index);
              },
              message: message,
              messageBubble: messageBubble,
              senderId: senderId);
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.message,
    required this.messageBubble,
    required this.senderId,
    required this.onLongPress,
  });

  final Message message;
  final Widget Function({required bool isMe, required Message message})
      messageBubble;
  final String senderId;
  final VoidCallback onLongPress;
  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(message.messageId),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: messageBubble(
          message: message,
          isMe: message.senderId == senderId,
        ),
      ),
    );
  }
}
