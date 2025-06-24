import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safe_sky/services/chat_service.dart';
import '../models/message.dart';

class Chat extends StatefulWidget {
  final String zoneId;
  final String displayName;

  Chat({required this.zoneId, required this.displayName});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final message = Message(
      senderId: _chatService.getCurrentUser()['uid'] ?? '',
      senderName: widget.displayName,
      content: content,
      timestamp: Timestamp.now(),
    );

    _chatService.postMessage(widget.zoneId, message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zone Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.zoneId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ListTile(
                        title: Text(msg.senderName),
                        subtitle: Text(msg.content),
                        trailing: Text(
                          msg.timestamp.toDate().toLocal().toString().substring(0, 16),
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
