import 'package:chaty/utils/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart'; // Import MessageType from Message model

class ChatSummary {
  final String chatId;
  final String lastMessage;
  final MessageType lastMessageType;
  final DateTime lastMessageTime;
  final List<String> users;
  final String otherUserId;
  final String lastMessageSenderId;
  final Map<String, int> unreadMessageCount;

  ChatSummary({
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.users,
    required this.otherUserId,
    required this.lastMessageSenderId,
    required this.unreadMessageCount, // 🔥 Initialize unreadCount
  });

  factory ChatSummary.fromMap(Map<String, dynamic> map, String currentUserId) {
    try {
      return ChatSummary(
        chatId: map['chatId'] ?? "",
        lastMessage: map['lastMessage'] ?? "No message",
        lastMessageSenderId: map['lastMessageSender'] ?? "Unknown",
        lastMessageType: MessageType.values.any((e) =>
                e.toString().split('.').last ==
                (map['lastMessageType'] ?? "text"))
            ? MessageType.values.firstWhere(
                (e) =>
                    e.toString().split('.').last ==
                    (map['lastMessageType'] ?? "text"),
              )
            : MessageType.text,
        lastMessageTime:
            (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        users: List<String>.from(map['users'] ?? []),
        otherUserId: (map['users'] is List && (map['users'] as List).isNotEmpty)
            ? (map['users'] as List<dynamic>)
                .map((e) => e.toString())
                .firstWhere((id) => id != currentUserId,
                    orElse: () => "Unknown")
            : "Unknown",
        unreadMessageCount: Map<String, int>.from(map['unreadMessageCount'] ??
            {}), // 🔥 Fetch unread count from Firestore
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
        unreadMessageCount: {}, // 🔥 Default unread count to 0
      );
    }
  }

  // Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType.toString().split('.').last,
      'lastMessageTime': lastMessageTime,
      'users': users,
      'lastMessageSender': lastMessageSenderId,
      'unreadMessageCount':
          unreadMessageCount, // 🔥 Store unreadCount in Firestore
    };
  }
}
