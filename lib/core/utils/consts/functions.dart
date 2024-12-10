import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// generate callID from random numbers
String generateRandomNumber(int length) {
  final Random random = Random();
  String number = '';

  for (int i = 0; i < length; i++) {
    number += random.nextInt(10).toString();
  }

  return number;
}

/// generate sessionID
String sessionId = const Uuid().v4();

/// generate callID from random letters and numbers
const _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
Random _rnd = Random();

String generateCallId(int length) =>
    String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

/// generate username for email from random letters
const _letter = 'abcdefghijklmnopqrstuvwxyz';
Random _randomEmail = Random();

String generateEmail() =>
    String.fromCharCodes(Iterable.generate(10, (_) => _letter.codeUnitAt(_randomEmail.nextInt(_letter.length))));

/// generate JWT
String generateJwt({required String userId, required String secretKey, int expiryMinutes = 60}) {
  final jwt = JWT({
    'user_id': userId,
    'exp': DateTime.now().add(Duration(minutes: expiryMinutes)).millisecondsSinceEpoch ~/ 1000,
  });
  return jwt.sign(SecretKey(secretKey), algorithm: JWTAlgorithm.HS256);
}

/// Fetch user ID from FirebaseAuth
Future<String?> fetchUserIdFromFirebase() async {
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  return firebaseUser?.uid;
}

// * permission dialog
void showPermissionDialog(BuildContext context, String permission) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("$permission Permission Required"),
        content: Text("Please allow access to $permission for the call to proceed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => openAppSettings(), child: const Text('Go to Settings')),
        ],
      );
    },
  );
}

/// private functions
// * need camera, microphone, and notifications permissions
Future<void> checkAndRequestPermissions(BuildContext context) async {
  final cameraStatus = await Permission.camera.request();
  final micStatus = await Permission.microphone.request();
  final notifStatus = await Permission.notification.request();

  if (cameraStatus.isDenied || micStatus.isDenied || notifStatus.isDenied) {
    showPermissionDialog(context, "Permissions required");
  }
}