import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, String> getCurrentUser() {
    final user = _auth.currentUser;
    return {
      'displayName': user?.displayName ?? '',
      'email': user?.email ?? '',
      'uid': user?.uid ?? '',
    };
  }

  Future<void> postMessage(String reportId, Message message) async {
    await _firestore
        .collection('dangerReports')
        .doc(reportId)
        .collection('chat')
        .add(message.toMap());
  }

  Future<List<Message>> getAllMessages(String reportId) async {
    final querySnapshot = await _firestore
        .collection('dangerReports')
        .doc(reportId)
        .collection('chat')
        .orderBy('timestamp')
        .get();

    return querySnapshot.docs
        .map((doc) => Message.fromMap(doc.data()))
        .toList();
  }

  Stream<List<Message>> getMessagesStream(String reportId) {
    return _firestore
        .collection('dangerReports')
        .doc(reportId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }
}
