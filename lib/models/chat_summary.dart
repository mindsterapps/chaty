import 'package:chaty/utils/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart'; // Import MessageType from Message model

class ChatSummary {
  final String chatId;
  final String lastMessage;
  final MessageType lastMessageType;
  final DateTime lastMessageTime; // Changed to DateTime
  final List<String> users;
  final String otherUserId;
  final String lastMessageSenderId;

  ChatSummary({
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.users,
    required this.otherUserId,
    required this.lastMessageSenderId,
  });

  factory ChatSummary.fromMap(Map<String, dynamic> map, String currentUserId) {
    try {
      return ChatSummary(
        lastMessageSenderId: map['lastMessageSender'] ?? "Unknown",
        chatId: map['chatId'] ?? "",
        lastMessage: map['lastMessage'] ?? "No message",
        lastMessageType: MessageType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (map['lastMessageType'] ?? "text"),
          orElse: () => MessageType.text,
        ),
        lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
        users: List<String>.from(map['users'] ?? []),
        otherUserId: (map['users'] as List<dynamic>)
            .map((e) => e.toString())
            .firstWhere((id) => id != currentUserId,
                orElse: () => "Unknown User"),
      );
    } catch (e) {
      e.log("❌ Error converting Firestore data to ChatSummary");
      return ChatSummary(
        chatId: "",
        lastMessage: "Error loading message",
        lastMessageType: MessageType.text,
        lastMessageTime: DateTime.now(),
        users: [],
        otherUserId: "Unknown",
        lastMessageSenderId: 'Unknown',
      );
    }
  }
}
