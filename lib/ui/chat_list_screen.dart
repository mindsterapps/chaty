import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_summary.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;
  final ChatService _chatService = ChatService();
  final Widget Function({required ChatSummary chatSummary})? chatTileBuilder;

  ChatListScreen({Key? key, required this.currentUserId, this.chatTileBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chats")),
      body: StreamBuilder<List<ChatSummary>>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No chats yet."));
          }

          List<ChatSummary> chats = snapshot.data!;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              if (chatTileBuilder != null) {
                return chatTileBuilder!(chatSummary: chat);
              }
              return ListTile(
                title: Text("Chat with ${chat.otherUserId}"),
                subtitle: Text(chat.lastMessage),
                trailing: Text(chat.lastMessageTime
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderId: currentUserId,
                        receiverId: chat.otherUserId,
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
