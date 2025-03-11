enum MessageStatus {
  delivered,
  unread,
  read,
}

class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? mediaUrl;
  final DateTime timestamp;
  final MessageStatus status; // Added status field

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    required this.status, // Initialize status
  });

  // Convert Message to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last, // Save as string
    };
  }

  // Convert Firestore document to Message
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      timestamp: DateTime.parse(map['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () =>
            MessageStatus.unread, // Default to unread if status is missing
      ),
    );
  }
}
