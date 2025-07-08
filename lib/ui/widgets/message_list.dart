import 'dart:async';

import 'package:chaty/services/chat_service.dart';
import 'package:chaty/ui/widgets/date_divider.dart';
import 'package:chaty/ui/widgets/message_bubble.dart';
import 'package:chaty/utils/extensions.dart';
import 'package:chaty/utils/selection_controller.dart';
import 'package:flutter/material.dart';
import '../../models/message.dart';

/// A widget that displays a scrollable list of chat messages between two users.
///
/// Supports message selection, deletion, custom message bubbles, and loading more messages.
class ChatMessageList extends StatefulWidget {
  /// The ID of the user sending messages.
  final String senderId;

  /// The ID of the user receiving messages.
  final String receiverId;

  /// The initial number of chat messages to load.
  final int initialChatLimit;

  /// Optional callback to provide the last seen time of the receiver.
  final Function(DateTime lastSeen)? getLastSeen;

  /// Optional callback for when a message is deleted.
  final Function()? onDeleteMessage;

  /// Optional builder for customizing the message bubble widget.
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;

  /// Divide chat date-vise, [label] will be the divided date.
  final Widget Function(String label)? dividerBuilder;

  /// Enable/disable date-vise divider.
  /// Default value will be ``true``
  final bool enableDivider;

  /// Optional callback for sending selected messages.
  final bool enableSwipeToDelete;

  /// Optional callback for when messages are selected.
  final void Function(
      {required List<Message> messages,
      required void Function() deselectAll,
      required void Function() deleteAll})? onMessageSelected;

  /// The padding to apply around the message list.
  ///
  /// This defines the amount of space to inset the children of the message list
  /// from the edges of its container.
  final EdgeInsets? listPadding;

  /// Creates a [ChatMessageList] widget.
  const ChatMessageList({
    required this.enableSwipeToDelete,
    required this.senderId,
    required this.receiverId,
    required this.enableDivider,
    this.initialChatLimit = 15,
    this.getLastSeen,
    this.onDeleteMessage,
    this.dividerBuilder,
    this.messageBubbleBuilder,
    this.listPadding,
    Key? key,
    this.onMessageSelected,
  }) : super(key: key);

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

/// State for [ChatMessageList], manages message loading, selection, and UI updates.
class _ChatMessageListState extends State<ChatMessageList> {
  final ChatService _chatService = ChatService.instance;
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  Message? _lastMessage;
  bool _hasMoreMessages = true;
  late final String chatId;
  StreamSubscription? _messageSub;

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
            .toList()
            .reversed
            .toList(),
        deselectAll: clearSelection,
        deleteAll: () {
          _chatService
              .deleteMessages(
            chatId: chatId,
            messageIds: _messages
                .where((e) => selectedController.isSelected(e.messageId))
                .map((e) => e.messageId)
                .toList(),
          )
              .then(
            (value) {
              setState(() {});
            },
          );
        },
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
    if (_isLoadingMore.value || !_hasMoreMessages || _lastMessage == null) {
      _isLoadingMore.value.log('isLoadingMore.value');
      _hasMoreMessages.log('hasMoreMessages');
      _lastMessage.log('lastMessage');
      return;
    }
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
      ''.log('No more messages');
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
      // _loadMoreMessages();
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
                  onRefresh: () => _loadMoreMessages(),
                  child: ListView.builder(
                    padding: widget.listPadding,
                    cacheExtent: 10000,
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == widget.senderId;

                      // Get previous message date (if any)
                      DateTime? previousDate;
                      if (index + 1 < _messages.length) {
                        previousDate = _messages[index + 1].timestamp;
                      }
                      // Check if this message is from a new day
                      final showDateDivider = previousDate == null ||
                          !isSameDate(previousDate, message.timestamp);

                      ValueNotifier<bool> swipe = ValueNotifier(false);
                      if (message.isDeleted) return Container();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateDivider && widget.enableDivider)
                            widget.dividerBuilder?.call(
                                  formatDateDivider(message.timestamp),
                                ) ??
                                DateDivider(
                                  label: formatDateDivider(message.timestamp),
                                ),
                          GestureDetector(
                            onPanUpdate: (details) {
                              // Swiping in right direction.
                              if (details.delta.dx > 0) {}

                              // Swiping in left direction.
                              if (details.delta.dx < 0) {
                                if (isMe && widget.enableSwipeToDelete)
                                  swipe.value = !swipe.value;
                              }
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
                                FocusManager.instance.primaryFocus?.unfocus();
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
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.cancel,
                                                          color: Colors.grey),
                                                      onPressed: () {
                                                        swipe.value =
                                                            !swipe.value;
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
                                                    isMe: isMe,
                                                    message: message),
                                      );
                                    })),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
        ),
      ],
    );
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return "Today";
    } else if (msgDate == today.subtract(Duration(days: 1))) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
