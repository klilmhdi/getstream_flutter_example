// firebase_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:getstream_flutter_example/features/data/models/calling_model.dart';
import 'package:getstream_flutter_example/features/data/models/live_stream_model.dart';
import 'package:getstream_flutter_example/features/data/models/meetings_model.dart';
import 'package:getstream_flutter_example/features/data/models/user_model.dart';

class FirebaseServices {
  ///==================== > Variables
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

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

  ///==================== > Save FCM Token to
  Future<void> saveFcmToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': fcmToken});
    }
  }

  ///==================== > Upload user data to FirebaseFirestore
  Future<void> uploadUserDataToFirebase(
    String uid, {
    required String name,
    required String email,
    required String role,
    required String token,
  }) async {
    String platform = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
        ? "Mobile"
        : "Web";

    final UserModel userModel =
        UserModel(uid: uid, name: name, email: email, role: role, platform: platform, token: token, isActiveUser: true);

    await firestore.collection("users").doc(uid).set(userModel.toMap());
    await database.ref('users').child(uid).set(userModel.toMap());
  }

  ///==================== > Upload call data to Firebase Firestore Database and Real-Time Database
  Future<void> uploadCallDataToFirebase(CallingModel calling) async {
    await Future.wait([
      // upload to firebase firestore database
      firestore.collection("calls").doc(calling.callID).set(calling.toMap()),

      // upload to real time database
      database.ref('calls/${calling.callID}').set(calling.toMap()),
    ]);
  }

  ///==================== > Upload meet data to FirebaseFirestore
  Future<void> uploadMeetDataToFirebase(MeetingModel meeting) async {
    await firestore.collection("meets").doc(meeting.meetID).set(meeting.toMap());
    await database.ref('meets/${meeting.meetID}').set(meeting.toMap());
  }

  ///==================== > Upload livestream data to Firebase Firestore Database and Real-Time Database
  Future<void> uploadLiveStreamDataToFirebase(LiveStreamModel living) async =>
      await firestore.collection("livestreams").doc(living.id).set({
        'id': living.id,
        'title': living.title,
        'creatorId': living.creatorId,
        'creatorName': living.creatorName,
        'isLive': living.isLive,
        'duration': living.duration.inSeconds,
        'startTime': living.startTime.toIso8601String(),
        'endTime': living.endTime?.toIso8601String(),
        'subscriptionsId': living.subscriptionsId,
        'subscriptionsName': living.subscriptionsName,
      });

  ///==================== > Get user data from FirebaseFirestore
  Future<DocumentSnapshot> getUserDataFromFirebase(String uid) async =>
      await firestore.collection("users").doc(uid).get();

  ///==================== > Get caller data from calls collections in FirebaseFirestore
  Future<Map<String, dynamic>?> getCallerDetails(String callId) async =>
      await FirebaseServices().firestore.collection('calls').doc(callId).get().then(
        (value) {
          if (value.exists) {
            return {
              'callerId': value['callerID'],
              'callerName': value['callerName'],
            };
          }
        },
      ).catchError((onError, StackTrace stk) {
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${onError.toString()}");
        print(">?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StackError: ${stk.toString()}");
      });

  /// Update Call Duration
  Future<void> updateCallDuration(String callID, Duration duration) async {
    final durationSeconds = duration.inSeconds;

    await Future.wait([
      firestore.collection("calls").doc(callID).update({'duration': durationSeconds}),
      database.ref('calls/$callID').update({'duration': durationSeconds}),
    ]);
  }

  ///==================== > check if current user is teacher
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
  Future<void> login({required String email, required String password}) async =>
      await auth.signInWithEmailAndPassword(email: email, password: password);

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

  Future<UserCredential> signUpWithEmail({required String email, required String password}) async =>
      await auth.createUserWithEmailAndPassword(email: email, password: password);
}
