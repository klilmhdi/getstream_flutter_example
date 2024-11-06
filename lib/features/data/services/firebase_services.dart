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
    // String collectionName = role.toLowerCase() == 'teacher' ? 'teachers' : 'students';

    await firestore.collection("users").doc(uid).set({
      'userId': uid,
      'name': name,
      'email': email,
      'token': kIsWeb ? const Uuid().v4().toString() : token,
      'role': role,
      'platform': kIsWeb ? "Web" : "Mobile",
      'createdAt': Timestamp.now(),
      'isActiveUser': true
    });
  }

  ///==================== > Upload call data to FirebaseFirestore
  Future<void> uploadCallDataToFirebase(
    String uid, {
    required String callerId,
    required String callingId,
    required String callId,
    required bool callIsActive,
  }) async {
    await firestore.collection("calls").doc(callId).set({
      'callId': callId,
      'callerId': callerId,
      'callingId': callingId,
      'isActive': callIsActive,
    });
  }

  /*
  create update function for call
    'createdAt': Timestamp.now(),
    'startCallDuration': 0,
    'endCallDuration': 0,
   */

  ///==================== > Get user data from FirebaseFirestore
  Future<DocumentSnapshot> getUserDataFromFirebase(String uid) async {
    return await firestore.collection("users").doc(uid).get();
  }

  Future<bool> checkIfCurrentUserIsTeacher() async {
    try {
      final userDoc =
          await FirebaseServices().firestore.collection("users").doc(FirebaseServices().auth.currentUser?.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'];
        print("User role from Firestore: $role");
        return role == "Teacher";
      } else {
        print("User document not found.");
        return false;
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return false;
    }
  }

  ///==================== > Other Methods (login, logout, etc.)
  ///==================== > login
  Future<void> login({required String email, required String password}) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  ///==================== > logout
  Future<void> logout() async {
    try {
      User? user = auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          await firestore.collection('users').doc(user.uid).update({'isActiveUser': false});
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
}
