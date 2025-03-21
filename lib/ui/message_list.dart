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
          return KeyedSubtree(
            key: ValueKey(messages[index].messageId),
            child: Dismissible(
              key: ValueKey(messages[index].timestamp),
              background: Container(
                color: Colors.red,
              ),
              onDismissed: (direction) =>
                  onDismiss(messageId: messages[index].messageId, index: index),
              child: Semantics(
                child: messageBubble(
                  message: messages[index],
                  isMe: messages[index].senderId == senderId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
