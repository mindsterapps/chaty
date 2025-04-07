import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  delivered,
  unread,
  read,
}

enum MessageType {
  text,
  audio,
  voice,
  image,
  document,
  video,
}

class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? mediaUrl;
  final DateTime timestamp;
  final MessageStatus status; // Added status field
  final MessageType type; // Added type field

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  // Convert Message to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
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
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MessageStatus.unread,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}
