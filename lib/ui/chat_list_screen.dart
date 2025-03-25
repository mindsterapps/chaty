import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;
  final ChatService _chatService = ChatService();

  ChatListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chats")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Show loader initially
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(child: Text("No chats yet."));
          }
          List<Map<String, dynamic>> chats = snapshot.data!;

          if (chats.isEmpty) return Center(child: Text("No chats yet."));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat["users"].firstWhere(
                  (id) => id != currentUserId); // Get the other user's ID

              return ListTile(
                title: Text("Chat with $otherUserId"),
                subtitle: Text(chat["lastMessage"]),
                trailing: Text(chat["lastMessageTime"]
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0]), // Format timestamp
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderId: currentUserId,
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
