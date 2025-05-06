import 'package:chaty/models/message.dart';
import 'package:chaty/services/chat_service.dart';
import 'package:chaty/ui/chat_list_screen.dart';
import 'package:chaty/ui/chat_screen.dart';
import 'package:chaty/utils/extensions.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Checks if the initialization has already been performed and avoids
  /// re-initializing if it has. This helps prevent redundant operations
  /// or potential errors caused by multiple initializations.
  await ChatService.instance.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chaty Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(), // Initial screen
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _user1Controller = TextEditingController();
  final TextEditingController _user2Controller = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chaty Example")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: _user1Controller,
              decoration: const InputDecoration(
                hintText: "Enter your name",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _user2Controller,
              decoration: const InputDecoration(
                hintText: "Enter another user's name",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to ChatScreen with sample data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      senderId: _user1Controller.text,
                      receiverId: _user2Controller.text,
                      mediaUploaderFunction: (mediaPath) async {
                        // Upload media to cloud storage
                        return Future.microtask(() => 'media_url.aac');
                      },
                      messageBubbleBuilder: (
                          {required isMe, required message}) {
                        return _MessageBubble(
                          isMe: isMe,
                          message: message,
                        );
                      },
                      sendMessageBuilder: (
                        context, {
                        required sendMediaMessage,
                        required sendMessage,
                      }) {
                        return _SendMessageWidget(
                          messageController: _messageController,
                          sendMessage: sendMessage,
                          sendAudioMessage: sendMediaMessage,
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text("Start Chat"),
            ),
            ElevatedButton(
                onPressed: () {
                  ChatListScreen(
                    currentUserId: _user1Controller.text,
                    chatTileBuilder: ({
                      required chatSummary,
                    }) {
                      return ListTile(
                        title: Text("Chat with ${chatSummary.otherUserId}"),
                        subtitle: Text(chatSummary.lastMessage),
                        trailing: Text(chatSummary.lastMessageTime
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                senderId: _user1Controller.text,
                                receiverId: chatSummary.otherUserId,
                                mediaUploaderFunction: (mediaPath) async {
                                  // Upload media to cloud storage
                                  return Future.microtask(
                                      () => 'media_url.aac');
                                },
                                messageBubbleBuilder: (
                                    {required isMe, required message}) {
                                  return _MessageBubble(
                                    isMe: isMe,
                                    message: message,
                                  );
                                },
                                sendMessageBuilder: (
                                  context, {
                                  required sendMediaMessage,
                                  required sendMessage,
                                }) {
                                  return _SendMessageWidget(
                                    messageController: _messageController,
                                    sendMessage: sendMessage,
                                    sendAudioMessage: sendMediaMessage,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    getnumberOfusers: (int numberOfusers) {},
                  );
                },
                child: Text('show list'))
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMe,
    required this.message,
  });
  final bool isMe;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              Image.network(
                message.mediaUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 5),
            Text(
              message.timestamp.timeAgo(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendMessageWidget extends StatelessWidget {
  const _SendMessageWidget({
    required TextEditingController messageController,
    required this.sendMessage,
    required this.sendAudioMessage,
  }) : _messageController = messageController;
  final void Function(String msg) sendMessage;
  final void Function(String msg, MessageType type) sendAudioMessage;
  final TextEditingController _messageController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.red),
            onPressed: () {
              // Send audio message
              sendAudioMessage('audio_path', MessageType.voice);
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (text) {
                // Send text message
                sendMessage(text);
              },
              decoration: const InputDecoration(
                hintText: "Type a message...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              // Send text message
              sendMessage(_messageController.text);
            },
          ),
        ],
      ),
    );
  }
}
