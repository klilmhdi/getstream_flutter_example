import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

List<CallReactionData> callReactions = const [
  CallReactionData(
    type: 'Fireworks',
    emojiCode: ':fireworks:',
    icon: '🎉',
  ),
  CallReactionData(
    type: 'Liked',
    emojiCode: ':like:',
    icon: '👍',
  ),
  CallReactionData(
    type: 'Dislike',
    emojiCode: ':dislike:',
    icon: '👎',
  ),
  CallReactionData(
    type: 'Smile',
    emojiCode: ':smile:',
    icon: '😊',
  ),
  CallReactionData(
    type: 'Heart',
    emojiCode: ':heart:',
    icon: '♥️',
  ),
  CallReactionData(
    emojiCode: ':raise-hand:',
    type: 'Raise hand',
    icon: '✋',
  )
];

showSuccessSnackBar(String title, int duration, BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(15),
        backgroundColor: CupertinoColors.activeGreen,
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: CupertinoColors.white,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  fontSize: 18,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

showErrorSnackBar(String title, int duration, BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(15),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: CupertinoColors.white,
              size: 30,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  fontSize: 18,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

void showConnectionLostDialog(BuildContext context, Function onReconnect, Function onCancel) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing the dialog by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Connection Lost'),
        content: const Text('Your connection to the internet has been lost. Would you like to try reconnecting or cancel the call?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onCancel(); // Execute the onCancel callback
            },
            child: const Text('Cancel Call', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              onReconnect(); // Execute the onReconnect callback
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Reconnect'),
          ),
        ],
      );
    },
  );
}

void showStudentCallCanceled(BuildContext context, Function yesFunction, Function noFunction, String teacherName) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing the dialog by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Call Cancel!'),
        content: Text('Are you sure to cancel the call with teacher: ${teacherName.toString()}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              noFunction(); // Execute the onCancel callback
            },
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              yesFunction(); // Execute the onReconnect callback
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}