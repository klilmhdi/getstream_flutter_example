import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final Call call;

  const IncomingCallScreen({required this.call});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Incoming Call',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.call_end),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await call.reject();
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await call.accept();
                    Navigator.pushAndRemoveUntil(
                        context, MaterialPageRoute(builder: (context) => CallScreen(call: call)), (route) => false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
