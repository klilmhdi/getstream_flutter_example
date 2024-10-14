// firebase_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:getstream_flutter_example/core/utils/consts/functions.dart';
import 'package:uuid/uuid.dart';

class FirebaseServices {
  ///==================== > Variables
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ///==================== > Init FCM Token
  static Future<String?> initFcmToken() async {
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    try {
      final String? fcmToken = await firebaseMessaging.getToken();
      print("FCM Token: $fcmToken");
      return fcmToken;
    } catch (onError) {
      print("FCM Token Error: ${onError.toString()}");
      return null;
    }
  }

  ///==================== > Upload user data to FirebaseFirestore
  Future<void> uploadUserDataToFirebase(
    String uid, {
    required String name,
    required String email,
    required String role,
  }) async {
    final String? token = await initFcmToken();
    String collectionName = role.toLowerCase() == 'teacher' ? 'teachers' : 'students';

    await firestore.collection("users").doc(collectionName).collection(uid).doc(uid).set({
      'userId': uid,
      'name': name,
      'email': email,
      'token': kIsWeb ? const Uuid().v4().toString() : token,
      'role': role,
      'platform': kIsWeb ? "Web" : "Mobile",
      'createdAt': Timestamp.now(),
      'isActive': true
    });
  }

  ///==================== > Other Methods (login, logout, etc.)
  Future<void> login({required String email, required String password}) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    try {
      User? user = auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          String collectionName = role.toLowerCase() == 'teacher' ? 'teachers' : 'students';

          await firestore
              .collection('users')
              .doc(collectionName)
              .collection(user.uid)
              .doc(user.uid)
              .update({'isActive': false});
          await auth.signOut();
        } else {
          print("User document does not exist.");
        }
      }
    } catch (e) {
      print("Error signing out: ${e.toString()}");
    }
  }

  Future<UserCredential> signUpWithEmail({required String email, required String password}) async {
    return await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  ///==================== > Get user data from FirebaseFirestore
  Future<DocumentSnapshot> getUserDataFromFirebase(String uid) async {
    return await firestore.collection("users").doc(uid).get();
  }
}