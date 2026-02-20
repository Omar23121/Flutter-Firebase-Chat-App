import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserEmail;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    // Generate chat ID by sorting UIDs alphabetically
    final currentUserId = _auth.currentUser!.uid;
    final List<String> ids = [currentUserId, widget.otherUserId];
    ids.sort();
    _chatId = '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('private_chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text': _messageController.text.trim(),
        'sender': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserEmail),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                _firestore
                    .collection('private_chats')
                    .doc(_chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading messages'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Start chatting!'),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message =
                      messages[index].data() as Map<String, dynamic>;
                      final text = message['text'] ?? '';
                      final senderUid = message['sender'] ?? '';
                      final timestamp = message['timestamp'] as Timestamp?;
                      final isCurrentUser = senderUid == _auth.currentUser?.uid;

                      String timeString = '';
                      if (timestamp != null) {
                        final dateTime = timestamp.toDate();
                        timeString =
                        '${dateTime.hour.toString().padLeft(2, '0')}:'
                            '${dateTime.minute.toString().padLeft(2, '0')}';
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Align(
                          alignment:
                          isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                              isCurrentUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    color:
                                    isCurrentUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                if (timeString.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    timeString,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                      isCurrentUser
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Message Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
