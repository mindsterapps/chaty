import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/message.dart' as model; 

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase Messaging & Local Notifications
  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission();

    // Get FCM token for this device
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Initialize local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);
  }

  /// Show notification when app is in foreground
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0, // Notification ID
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      details,
    );
  }

  /// Send push notification to a user
  Future<void> sendNotification(String receiverId, model.Message message) async {
    // Get recipient's FCM token
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(receiverId).get();
    String? token = userDoc['firebaseToken'];

    if (token != null) {
      // Send notification via Firebase Cloud Messaging
      await FirebaseMessaging.instance.sendMessage(
        to: token,
        data: {
          'title': "New Message from ${message.senderId}",
          'body': message.text,
          'chatId': message.receiverId,
        },
      );
    }
  }
}
