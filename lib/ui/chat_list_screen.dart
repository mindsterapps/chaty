import 'package:chaty/utils/extensions.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_summary.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  final Widget Function({required ChatSummary chatSummary})? chatTileBuilder;
  final Function(int numberOfusers)? getnumberOfusers;

  ChatListScreen({
    Key? key,
    required this.currentUserId,
    this.chatTileBuilder,
    this.getnumberOfusers,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService.instance;

  List<ChatSummary> _cachedChats = [];
  // Cached chat list
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<ChatSummary>>(
        stream: _chatService.getUserChats(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedChats.isEmpty) {
            return Center(
                child: CircularProgressIndicator()); // Show loader initially
          }

          if (snapshot.hasData && snapshot.data != null) {
            _cachedChats = snapshot.data!; // Update cache when new data arrives
          }

          if (_cachedChats.isEmpty) {
            return Center(child: Text("No chats yet."));
          }

          List<ChatSummary> chats = _cachedChats;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              widget.getnumberOfusers ?? (chats.length);
              final chat = chats[index];

              if (widget.chatTileBuilder != null) {
                return widget.chatTileBuilder!(chatSummary: chat);
              }
              return ListTile(
                leading: chat.unreadCount > 0
                    ? CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 6,
                      )
                    : SizedBox(), // ✅ Show dot if unreadCount > 0,
                title: Text("Chat with ${chat.otherUserId}"),
                subtitle: Text(chat.lastMessage),
                trailing: Text(chat.lastMessageTime
                    .toLocal()
                    .toString()
                    .log('last message time')
                    .split(' ')[1]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderId: widget.currentUserId,
                        receiverId: chat.otherUserId,
                        intialChatLimit: 15,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
