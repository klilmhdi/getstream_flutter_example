import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebNotificationController {
  html.AudioElement? _ringtoneAudio;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void sendNotification (Widget meetScreen) {
    if (kIsWeb) {
      html.window.on['call-accepted'].listen((event) {
        // Handle call accepted in Flutter
        print('Flutter: Call was accepted from notification.');
        _stopRingtone();
        // Navigate to HelloScreen
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => meetScreen),
        );
      });

      html.window.on['call-canceled'].listen((event) {
        print('Flutter: Call was canceled from notification.');
        _stopRingtone();
        _showCallCanceledSnackbar();
      });

      html.window.on['play-audio'].listen((event) {
        print('Flutter: Play audio event received.');
        _playRingtone();
      });
    }
  }
  void _playRingtone() {
    if (_ringtoneAudio == null) {
      print('Flutter: Starting ringtone.');
      _ringtoneAudio = html.AudioElement('assets/ring.mp3')
        ..autoplay = true
        ..loop = true
        ..onError.listen((event) {
          print('Flutter: Error playing audio: ${event.toString()}');
        });
      html.document.body?.append(_ringtoneAudio!);
    } else {
      print('Flutter: Ringtone is already playing.');
    }
  }

  void _stopRingtone() {
    if (_ringtoneAudio != null) {
      print('Flutter: Stopping ringtone.');
      _ringtoneAudio!.pause();
      _ringtoneAudio!.remove(); // Remove from DOM
      _ringtoneAudio = null;
    } else {
      print('Flutter: No ringtone is playing.');
    }
  }

  void _showCallCanceledSnackbar() {
    final currentContext = _navigatorKey.currentState?.context;
    if (currentContext != null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Call was canceled.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('Flutter: Unable to show snackbar - context is null.');
    }
  }

}
