import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  final ChatService _chatService = ChatService();

  ChatListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _cachedChats = []; // Store chats locally

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chats")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget._chatService.getUserChats(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedChats.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            _cachedChats = snapshot.data!; // Update cache when new data arrives
          }

          if (_cachedChats.isEmpty) {
            return Center(child: Text("No chats yet."));
          }

          return ListView.builder(
            itemCount: _cachedChats.length,
            itemBuilder: (context, index) {
              final chat = _cachedChats[index];
              final otherUserId = chat["users"].firstWhere(
                  (id) => id != widget.currentUserId,
                  orElse: () => "Unknown User");

              return ListTile(
                title: Text("Chat with $otherUserId"),
                subtitle: Text(chat["lastMessage"] ?? ""),
                trailing: Text(
                  chat["lastMessageTime"] != null
                      ? chat["lastMessageTime"]
                          .toDate()
                          .toLocal()
                          .toString()
                          .split(' ')[0]
                      : "N/A",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderId: widget.currentUserId,
                        receiverId: otherUserId,
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
