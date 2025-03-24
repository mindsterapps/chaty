import 'package:flutter/material.dart';
import '../models/message.dart';

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
