import 'dart:io';

import 'package:chaty/services/storage_services.dart';
import 'package:chaty/utils/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a new message
  Future<void> sendMessage(Message message) async {
    DocumentReference messageRef = _firestore
        .collection('chats')
        .doc(getChatId(message.senderId, message.receiverId))
        .collection('messages')
        .doc(message.messageId);

    await messageRef.set(message.toMap());
  }

  late QueryDocumentSnapshot<Map<String, dynamic>> lastDocument;

  /// Fetch messages in real-time
  Stream<List<Message>> getMessages(String chatId) {
    print(chatId);
    final snap = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return snap.map((snapshot) {
      lastDocument = snapshot.docs.last;
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
  }

  int initialLimit = 5;
  Future<List<Message>> fetchMessages(String chatId,
      {Message? lastMessage}) async {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(initialLimit);

    if (lastMessage != null) {
      query = query.startAfter([lastMessage.toMap()['timestamp']]);
    }

    QuerySnapshot querySnapshot = await query.get();

    print("🔥 Fetching messages for chatId: $chatId");
    print("🔥 Last Timestamp: ${lastMessage?.timestamp}");
    print("🔥 Query Retrieved Messages: ${querySnapshot.docs.length}");

    // Print all retrieved message timestamps
    for (var doc in querySnapshot.docs) {
      print(
          "🔥 Message Timestamp: ${(doc.data() as Map<String, dynamic>)['timestamp']}");
    }

    List<Message> messages = querySnapshot.docs
        .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return messages;
  }

  Stream<List<Message>> streamLatestMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId.log('chatId'))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(initialLimit) // Stream the latest 20 messages
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data().log('doc')))
            .toList());
  }

  /// Update message status (delivered, unread, read)
  Future<void> updateMessageStatus(
      String chatId, String messageId, MessageStatus status) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status.toString().split('.').last});
  }

  /// Generate a unique chat ID based on user IDs
  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? "$user1\_$user2"
        : "$user2\_$user1";
  }

  final StorageService _storageService = StorageService();

  /// Delete a message and its associated media (if any)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      DocumentReference messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      DocumentSnapshot messageSnapshot = await messageRef.get();

      if (messageSnapshot.exists) {
        Message message =
            Message.fromMap(messageSnapshot.data() as Map<String, dynamic>);

        // If the message has a media URL, delete the media file
        if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
          await _storageService.deleteMedia(message.mediaUrl!);
        }

        // Delete the message from Firestore
        await messageRef.delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  /// Mark all unread messages as "read" when the recipient opens the chat
  Future<void> markMessagesAsRead(String chatId, String receiverId) async {
    QuerySnapshot messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId',
            isEqualTo: receiverId) // Messages meant for this user
        .where('status', isEqualTo: 'unread')
        .get();

    for (var doc in messages.docs) {
      doc.reference.update({'status': 'read'});
    }
  }

  /// Update typing status in Firestore
  Future<void> updateTypingStatus(
      String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  /// Listen to typing status changes
  Stream<Map<String, dynamic>?> getTypingStatus(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map(
      (snapshot) {
        if (snapshot.exists && snapshot.data()!.containsKey('typingStatus')) {
          return snapshot.data()!['typingStatus'] as Map<String, dynamic>;
        }
        return null;
      },
    );
  }

  String uploadAudio(File audioFile) => '';
}
