import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatBottomSheet extends StatelessWidget {
  const ChatBottomSheet({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    if (channel.state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamChannel(
        channel: channel,
        child: const Column(children: [Flexible(child: StreamMessageListView()), StreamMessageInput()]));
  }
}
