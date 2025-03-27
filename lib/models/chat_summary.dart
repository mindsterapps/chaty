import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart'; // Import MessageType from Message model

class ChatSummary {
  final String chatId;
  final String lastMessage;
  final MessageType lastMessageType; // Use the same MessageType enum
  final DateTime lastMessageTime;
  final List<String> users;
  final String otherUserId;

  ChatSummary({
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.users,
    required this.otherUserId,
  });

  factory ChatSummary.fromMap(Map<String, dynamic> map, String currentUserId) {
    return ChatSummary(
      chatId: map['chatId'],
      lastMessage: map['lastMessage'] ?? "No message",
      lastMessageType: MessageType.values.firstWhere(
        (e) =>
            e.toString().split('.').last == (map['lastMessageType'] ?? "text"),
        orElse: () => MessageType.text,
      ),
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      users: List<String>.from(map['users']),
      otherUserId: List<String>.from(map['users']).firstWhere(
        (id) => id != currentUserId,
        orElse: () => "Unknown User",
      ),
    );
  }
}
