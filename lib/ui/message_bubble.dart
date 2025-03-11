import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: message.mediaUrl != null
                ? Image.network(message.mediaUrl!, width: 200)
                : Text(message.text,
                    style: const TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: Text(
              isMe
                  ? message.status == MessageStatus.read
                      ? "✔✔ Read"
                      : message.status == MessageStatus.delivered
                          ? "✔ Delivered"
                          : "✔ Sent"
                  : "",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
