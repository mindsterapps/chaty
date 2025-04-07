import 'dart:async';
import 'dart:ffi';

import 'package:chaty/services/chat_service.dart';
import 'package:chaty/ui/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import '../models/message.dart';

class ChatMessageList extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final int initialChatLimit;
  final Function(DateTime lastSeen)? getLastSeen;
  final Function()? onDeleteMessage;
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;
  final void Function({required List<Message> messages})? onMessageSelected;

  const ChatMessageList({
    required this.senderId,
    required this.receiverId,
    this.initialChatLimit = 15,
    this.getLastSeen,
    this.onDeleteMessage,
    this.messageBubbleBuilder,
    Key? key,
    this.onMessageSelected,
  }) : super(key: key);

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ChatService _chatService = ChatService.instance;
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

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
    selectedController.addListener(() {
      widget.onMessageSelected?.call(
        messages: _messages
            .where(
                (message) => selectedController.isSelected(message.messageId))
            .toList(),
      );
    });
    super.initState();
  }

  void _listenToMessages() {
    _messageSub =
        _chatService.streamLatestMessages(chatId).listen((newMessages) {
      if (!mounted) return;
      setState(() {
        for (var msg in newMessages.reversed) {
          if (!_messages.any((m) => m.messageId == msg.messageId)) {
            _messages.insert(0, msg);
          }
        }
        if (_messages.isNotEmpty) {
          _lastMessage = newMessages.last;
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

  void _confirmDeleteMessage(Message message) async {
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
      await _chatService.deleteMessage(chatId, message.messageId);
      setState(() {
        _messages.removeWhere((msg) => msg.messageId == message.messageId);
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

  SelectedController selectedController = SelectedController();
  void selectAllMessages() {
    selectedController.selectAll(_messages);
  }

  void clearSelection() {
    selectedController.clearSelection();
  }

  void toggleSelection(String messageId) {
    selectedController.toggleSelection(messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
          valueListenable: selectedController,
          builder: (context, value, child) {
            return ListView.builder(
              cacheExtent: 10000,
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == widget.senderId;
                return SwipeTo(
                  onRightSwipe: (details) {
                    if (isMe) _confirmDeleteMessage(message);
                  },
                  child: GestureDetector(
                    onLongPress: () {
                      if (selectedController.isSelected(message.messageId)) {
                        selectedController.remove(message.messageId);
                      } else {
                        selectedController.add(message.messageId);
                      }
                    },
                    onTap: () {
                      if (selectedController.value.isEmpty) {
                        return;
                      }
                      if (selectedController.isSelected(message.messageId)) {
                        selectedController.remove(message.messageId);
                      } else {
                        selectedController.add(message.messageId);
                      }
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2,
                            color:
                                selectedController.isSelected(message.messageId)
                                    ? Colors.blue.withAlpha(20)
                                    : Colors.transparent,
                          ),
                          color:
                              selectedController.isSelected(message.messageId)
                                  ? Colors.blue.withAlpha(50)
                                  : Colors.transparent,
                        ),
                        child: widget.messageBubbleBuilder?.call(
                              message: message,
                              isMe: isMe,
                            ) ??
                            MessageBubble(isMe: isMe, message: message)),
                  ),
                );
              },
            );
          }),
    );
  }
}

class SelectedController extends ValueNotifier<List> {
  SelectedController() : super([]);

  void selectAll(List items) {
    value = items;
    notifyListeners();
  }

  void clearSelection() {
    value = [];
    notifyListeners();
  }

  bool isSelected(String id) {
    return value.contains(id);
  }

  void toggleSelection(String id) {
    if (value.contains(id)) {
      value.remove(id);
    } else {
      value.add(id);
    }
    notifyListeners();
  }

  void remove(String id) {
    value.remove(id);
    notifyListeners();
  }

  void add(String id) {
    value.add(id);
    notifyListeners();
  }

  void removeAll() {
    value = [];
    notifyListeners();
  }

  void addAll(List ids) {
    value.addAll(ids);
    notifyListeners();
  }
}
