import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSummary {
  final String chatId;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final List<String> users;
  final String otherUserId; // Extracted from users list

  ChatSummary({
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.users,
    required this.otherUserId,
  });

  factory ChatSummary.fromMap(Map<String, dynamic> map, String currentUserId) {
    return ChatSummary(
      chatId: map['chatId'],
      lastMessage: map['lastMessage'] ?? "No message",
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      users: List<String>.from(map['users']),
      otherUserId: List<String>.from(map['users']).firstWhere(
        (id) => id != currentUserId,
        orElse: () => "Unknown User",
      ),
    );
  }
}
