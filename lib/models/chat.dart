class Chat {
  final String chatId;
  final String customerId;
  final String nutritionistId;
  final String lastMessage;
  final DateTime lastMessageTime;

  Chat({
    required this.chatId,
    required this.customerId,
    required this.nutritionistId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  // Convert Chat to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'customerId': customerId,
      'nutritionistId': nutritionistId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  // Convert Firestore document to Chat
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
