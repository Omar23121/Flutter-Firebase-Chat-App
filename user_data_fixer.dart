import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// أداة لإصلاح بيانات المستخدم الحالي
/// استخدمها مرة واحدة لكل مستخدم لتحديث بياناته في Firestore
class UserDataFixer {
  static Future<void> ensureUserDataExists() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    try {
      final userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // إذا لم تكن البيانات موجودة، أنشئها
        debugPrint('⚠️ User data not found, creating...');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User data created successfully!');
      } else {
        // إذا كانت موجودة، تأكد من أن جميع الحقول موجودة
        final data = userDoc.data() as Map<String, dynamic>;

        if (!data.containsKey('uid') || !data.containsKey('email')) {
          debugPrint('⚠️ User data incomplete, updating...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('✅ User data updated successfully!');
        } else {
          debugPrint('✅ User data is already complete');
        }
      }

      // اطبع معلومات المستخدم للتأكد
      final updatedDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      debugPrint('📋 User data: ${updatedDoc.data()}');
    } catch (e) {
      debugPrint('❌ Error ensuring user data: $e');
      rethrow;
    }
  }

  /// فحص وإصلاح كل المستخدمين (للمطورين فقط)
  static Future<void> fixAllUsers() async {
    try {
      // هذه الطريقة تعمل فقط إذا كان لديك صلاحيات admin
      // أو يمكن استدعاؤها من Cloud Function

      debugPrint(
        '⚠️ This function should be run from Cloud Functions or Admin SDK',
      );
      debugPrint('Cannot list all auth users from client SDK');
    } catch (e) {
      debugPrint('❌ Error fixing users: $e');
    }
  }

  /// عرض جميع المستخدمين في Firestore
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').get();

      final users =
      snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'uid': data['uid'],
          'email': data['email'],
          'createdAt': data['createdAt'],
        };
      }).toList();

      debugPrint('📋 Total users in Firestore: ${users.length}');
      for (var user in users) {
        debugPrint('   - ${user['email']} (${user['uid']})');
      }

      return users;
    } catch (e) {
      debugPrint('❌ Error getting users: $e');
      return [];
    }
  }
}
