/// Represents a chat between a customer and a nutritionist.
class Chat {
  /// Unique identifier for the chat.
  final String chatId;

  /// The ID of the customer involved in the chat.
  final String customerId;

  /// The ID of the nutritionist involved in the chat.
  final String nutritionistId;

  /// The last message sent in the chat.
  final String lastMessage;

  /// The time when the last message was sent.
  final DateTime lastMessageTime;

  /// Creates a new [Chat] instance.
  Chat({
    required this.chatId,
    required this.customerId,
    required this.nutritionistId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  /// Converts this [Chat] instance to a [Map] for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'customerId': customerId,
      'nutritionistId': nutritionistId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  /// Creates a [Chat] instance from a Firestore document [map].
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'],
      customerId: map['customerId'],
      nutritionistId: map['nutritionistId'],
      lastMessage: map['lastMessage'],
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
    );
  }
}
