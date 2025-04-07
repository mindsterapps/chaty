import 'dart:async';

import 'package:chaty/services/chat_service.dart';
import 'package:chaty/ui/message_bubble.dart';
import 'package:chaty/utils/extensions.dart';
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
        for (var msg
            in newMessages.unique((message) => message.messageId).reversed) {
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
    if (_isLoadingMore.value || !_hasMoreMessages || _lastMessage == null) {
      ''.log('Already loading or no more messages');
      return;
    }
    _isLoadingMore.value = true;

    List<Message> olderMessages = await _chatService.fetchMessages(
      chatId,
      lastMessage: _messages.first.log('first msg'),
    );
    double beforeOffset = _scrollController.offset;
    double beforeMax = _scrollController.position.maxScrollExtent;

    if (olderMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(olderMessages);
        _lastMessage = olderMessages.last;
      });
    } else {
      ''.log('No more messages');
      _hasMoreMessages = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double afterMax = _scrollController.position.maxScrollExtent;
      double delta = afterMax - beforeMax;

      _scrollController.jumpTo(beforeOffset + delta);
    });

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
    await _chatService.deleteMessage(chatId, message.messageId);
    widget.onDeleteMessage?.call();
    setState(() {
      _messages.removeWhere((msg) => msg.messageId == message.messageId);
    });
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
    return Column(
      children: [
        if (_isLoadingMore.value) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ValueListenableBuilder(
              valueListenable: selectedController,
              builder: (context, value, child) {
                return RefreshIndicator(
                  onRefresh: _loadMoreMessages,
                  child: ListView.builder(
                    cacheExtent: 10000,
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == widget.senderId;
                      ValueNotifier<bool> swipe = ValueNotifier(false);
                      if (message.isDeleted) return Container();
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (isMe) swipe.value = !swipe.value;
                        },
                        onLongPress: () {
                          if (selectedController
                              .isSelected(message.messageId)) {
                            selectedController.remove(message.messageId);
                          } else {
                            selectedController.add(message.messageId);
                          }
                        },
                        onTap: () {
                          if (selectedController.value.isEmpty) {
                            return;
                          }
                          if (selectedController
                              .isSelected(message.messageId)) {
                            selectedController.remove(message.messageId);
                          } else {
                            selectedController.add(message.messageId);
                          }
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: selectedController
                                        .isSelected(message.messageId)
                                    ? Colors.blue.withAlpha(20)
                                    : Colors.transparent,
                              ),
                              color: selectedController
                                      .isSelected(message.messageId)
                                  ? Colors.blue.withAlpha(50)
                                  : Colors.transparent,
                            ),
                            child: ValueListenableBuilder(
                                valueListenable: swipe,
                                builder: (context, _, __) {
                                  return AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: swipe.value
                                        ? Container(
                                            key: ValueKey(2),
                                            width: 300,
                                            height: 100,
                                            color: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Are you sure you want to delete?",
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.cancel,
                                                      color: Colors.grey),
                                                  onPressed: () {
                                                    swipe.value = !swipe.value;
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    if (isMe)
                                                      _confirmDeleteMessage(
                                                          message);
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        : widget.messageBubbleBuilder?.call(
                                              message: message,
                                              isMe: isMe,
                                            ) ??
                                            MessageBubble(
                                                isMe: isMe, message: message),
                                  );
                                })),
                      );
                    },
                  ),
                );
              }),
        ),
      ],
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
