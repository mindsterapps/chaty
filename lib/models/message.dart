import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the status of a message in the chat system.
///
/// - [delivered]: The message has been delivered to the recipient.
/// - [unread]: The message has not been read by the recipient.
/// - [read]: The message has been read by the recipient.
// ignore: public_member_api_docs
enum MessageStatus { delivered, unread, read }

/// Represents the type of a message in the chat system.
///
/// - [text]: A plain text message.
/// - [audio]: An audio file message.
/// - [voice]: A voice note message.
/// - [image]: An image file message.
/// - [document]: A document file message.
/// - [video]: A video file message.
/// - [gif]: A GIF image message.
// ignore: public_member_api_docs
enum MessageType { text, audio, voice, image, document, video, gif }

/// Model class representing a chat message.
///
/// Contains all relevant information for a message, including sender, receiver, content, type, status, and metadata.
class Message {
  /// Unique identifier for the message.
  final String messageId;

  /// ID of the user who sent the message.
  final String senderId;

  /// ID of the user who receives the message.
  final String receiverId;

  /// The text content of the message.
  final String text;

  /// Optional URL for media attached to the message.
  final String? mediaUrl;

  /// Timestamp when the message was sent.
  final DateTime timestamp;

  /// Status of the message (delivered, unread, read).
  final MessageStatus status;

  /// Type of the message (text, audio, etc.).
  final MessageType type;

  /// Whether the message is deleted.
  final isDeleted;

  /// Creates a [Message] instance.
  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    required this.status,
    required this.type,
    this.isDeleted = false,
  });

  /// Converts the [Message] instance to a map for Firestore storage.
  ///
  /// If [useCurrentTime] is true, uses the server timestamp for 'timestamp'.
  Map<String, dynamic> toMap({bool useCurrentTime = false}) {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': useCurrentTime ? FieldValue.serverTimestamp() : timestamp,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'isDeleted': isDeleted,
    };
  }

  /// Creates a [Message] instance from a Firestore document map.
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
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
