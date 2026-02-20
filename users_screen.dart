import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'user_data_fixer.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // تأكد من وجود بيانات المستخدم عند فتح الشاشة
    _ensureUserData();
  }

  Future<void> _ensureUserData() async {
    try {
      await UserDataFixer.ensureUserDataExists();
    } catch (e) {
      debugPrint('Error ensuring user data: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isRefreshing = true;
    });

    // انتظر قليلاً لإعادة تحميل البيانات
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _openPrivateChat(String otherUserId, String otherUserEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
          otherUserId: otherUserId,
          otherUserEmail: otherUserEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final currentUserEmail = _auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Users', style: TextStyle(fontSize: 18)),
            if (currentUserEmail.isNotEmpty)
              Text(
                currentUserEmail,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshUsers,
            icon:
            _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, countSnapshot) {
                  final totalUsers = countSnapshot.data?.docs.length ?? 0;
                  final otherUsersCount = totalUsers > 0 ? totalUsers - 1 : 0;
                  return Column(
                    children: [
                      Text(
                        'Select a user to start chatting',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$otherUsersCount user(s) available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading users',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshUsers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading users...'),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data?.docs ?? [];

                  // Filter out the current user
                  final otherUsers =
                  users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['uid'] != currentUserId;
                  }).toList();

                  if (otherUsers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No other users yet.\nInvite your friends to join!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: otherUsers.length,
                    itemBuilder: (context, index) {
                      final userData =
                      otherUsers[index].data() as Map<String, dynamic>;
                      final email = userData['email'] ?? 'Unknown';
                      final userId = userData['uid'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                            child: Text(
                              email.isNotEmpty ? email[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'UID: ${userId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Icon(
                            Icons.chat_bubble,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () => _openPrivateChat(userId, email),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
