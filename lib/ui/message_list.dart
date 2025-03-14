import 'package:flutter/material.dart';
import '../models/message.dart';

class Messag  eList extends StatelessWidget {
  final List<Message> messages;
  final String senderId;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final Widget Function({required Message message, required bool isMe})
      messageBubble;
  const MessageList({
    super.key,
    required this.messages,
    required this.senderId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.messageBubble,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return messageBubble(
            message: messages[index],
            isMe: messages[index].senderId == senderId,
          );
        },
      ),
    );
  }
}
