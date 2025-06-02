import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_input.dart';

import 'dart:async';
import 'message_list.dart';

/// A screen for displaying and sending chat messages between two users.
///
/// Supports custom message input, message bubble, media upload, and message selection callbacks.
class ChatScreen extends StatefulWidget {
  /// The ID of the user sending messages.
  final String senderId;

  /// The ID of the user receiving messages.
  final String receiverId;

  /// The initial number of chat messages to load.
  final int? intialChatLimit;

  /// Whether to enable the delete message feature.
  final bool enableDeleteMessage;

  /// Optional builder for customizing the message input widget.
  /// This builder provides a context and functions to send text and media messages,
  /// and optionally handle typing status.
  /// If not provided, a default [MessageInput] widget will be used.
  /// This builder can also handle media messages.
  /// [onTypingMessage] have to call when the user types a message.
  /// It can be null if typing status is not needed.
  /// call [onTypingMessage] function in TextField's onChange.
  final Widget Function(
    BuildContext context, {
    required void Function(String txt) sendMessage,
    required void Function(String mediaPath, MessageType type) sendMediaMessage,
    void Function(String text)? onTypingMessage,
  })? sendMessageBuilder;

  /// Optional builder for customizing the message bubble widget.
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;

  /// Optional function for uploading media files.
  final Future<String> Function(String mediaPath)? mediaUploaderFunction;

  /// Optional callback to provide the last seen time of the receiver.
  final Function(DateTime lastSeen)? getLastSeen;

  /// Optional callback for when a message is deleted.
  final Function()? onDeleteMessage;

  /// Optional callback for when messages are selected.
  final void Function(
      {required List<Message> messages,
      required void Function() deselectAll})? onMessageSelected;

  /// Optional function to handle typing status updates.
  /// This function should be called when the user types a message.
  final Widget Function()? typingIdicationBuilder;

  /// Whether to enable typing status updates.
  /// If true, typing status will be sent when the user types a message.
  final bool enableTypingStatus;

  /// Creates a [ChatScreen] widget.
  /// deleteMessage feature is enabled by default.
  const ChatScreen({
    required this.senderId,
    required this.receiverId,
    this.enableDeleteMessage = true,
    this.sendMessageBuilder,
    this.messageBubbleBuilder,
    this.mediaUploaderFunction,
    this.intialChatLimit,
    this.getLastSeen,
    this.onDeleteMessage,
    this.enableTypingStatus = false,
    this.typingIdicationBuilder,
    Key? key,
    this.onMessageSelected,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// State for [ChatScreen], manages message sending, media upload, and UI updates.
class _ChatScreenState extends State<ChatScreen> {
  void _sendMessage(ChatService chatService, String text) {
    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: text,
      mediaUrl: null,
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );
    chatService.sendMessage(message);
  }

  void _sendMediaMessage(
      ChatService chatService, String? mediaPath, MessageType type) async {
    if (mediaPath == null) return;
    final path = await widget.mediaUploaderFunction?.call(mediaPath);
    if (path == null) return;

    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: '',
      type: type,
      mediaUrl: path,
      timestamp: DateTime.now(),
      status: MessageStatus.unread,
    );
    chatService.sendMessage(message);
  }

  Timer? _typingTimer;

  void onTyping(String text) {
    chatService.setTypingStatus(widget.senderId, widget.receiverId, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 5), () {
      chatService.setTypingStatus(widget.senderId, widget.receiverId, false);
    });
  }

  final chatService = ChatService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              enableDeleteMessage: widget.enableDeleteMessage,
              onMessageSelected: widget.onMessageSelected,
              senderId: widget.senderId,
              receiverId: widget.receiverId,
              initialChatLimit: widget.intialChatLimit ?? 15,
              getLastSeen: widget.getLastSeen,
              onDeleteMessage: widget.onDeleteMessage,
              messageBubbleBuilder: widget.messageBubbleBuilder,
            ),
          ),
          widget.typingIdicationBuilder?.call() ??
              (widget.enableTypingStatus
                  ? StreamBuilder<bool>(
                      stream: chatService.typingStatusStream(
                        widget.senderId,
                        widget.receiverId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Text("Typing...");
                        }
                        return SizedBox.shrink();
                      },
                    )
                  : SizedBox.shrink()),
          widget.sendMessageBuilder?.call(
                context,
                onTypingMessage: widget.enableTypingStatus ? onTyping : null,
                sendMessage: (txt) => _sendMessage(chatService, txt),
                sendMediaMessage: (path, type) =>
                    _sendMediaMessage(chatService, path, type),
              ) ??
              MessageInput(
                onSendMessage: (txt) => _sendMessage(chatService, txt),
                onSendAudioMessage: (path, type) =>
                    _sendMediaMessage(chatService, path, type),
              ),
        ],
      ),
    );
  }
}
