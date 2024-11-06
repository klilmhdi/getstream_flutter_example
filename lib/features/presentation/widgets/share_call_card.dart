import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/stream_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class ShareCallCard extends StatelessWidget {
  const ShareCallCard({required this.callId, super.key});

  final String callId;

  @override
  Widget build(BuildContext context) {
    final theme = StreamVideoTheme.of(context);
    return CircleAvatar(
      backgroundColor: CupertinoColors.white,
      child: IconButton(
        onPressed: () async => _copyId(context, theme),
        icon: const Icon(Icons.copy_all),
      ),
    );
  }

  void _copyId(context, theme) async {
    await Clipboard.setData(ClipboardData(text: callId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check, color: CupertinoColors.activeGreen),
              const SizedBox(width: 8),
              Text('Call ID copied to clipboard, Call ID: $callId',
                  style: theme.textTheme.body.copyWith(color: theme.colorTheme.textHighEmphasis))
            ],
          ),
        ),
      );
    }
  }
}
