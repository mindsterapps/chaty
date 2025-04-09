import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'message_input.dart';

import 'dart:async';
import 'message_list.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final int? intialChatLimit;
  final Widget Function(
    BuildContext context, {
    required void Function(String txt) sendMessage,
    required void Function(String mediaPath, MessageType type) sendMediaMessage,
  })? sendMessageBuilder;
  final Widget Function({required Message message, required bool isMe})?
      messageBubbleBuilder;
  final Future<String> Function(String mediaPath)? mediaUploaderFunction;
  final Function(DateTime lastSeen)? getLastSeen;
  final Function()? onDeleteMessage;
  final void Function(
      {required List<Message> messages,
      required void Function() deselectAll})? onMessageSelected;

  const ChatScreen({
    required this.senderId,
    required this.receiverId,
    this.sendMessageBuilder,
    this.messageBubbleBuilder,
    this.mediaUploaderFunction,
    this.intialChatLimit,
    this.getLastSeen,
    this.onDeleteMessage,
    Key? key,
    this.onMessageSelected,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

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

  final chatService = ChatService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              onMessageSelected: widget.onMessageSelected,
              senderId: widget.senderId,
              receiverId: widget.receiverId,
              initialChatLimit: widget.intialChatLimit ?? 15,
              getLastSeen: widget.getLastSeen,
              onDeleteMessage: widget.onDeleteMessage,
              messageBubbleBuilder: widget.messageBubbleBuilder,
            ),
          ),
          widget.sendMessageBuilder?.call(
                context,
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
