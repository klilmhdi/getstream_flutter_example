import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatBottomSheet extends StatelessWidget {
  const ChatBottomSheet({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    if (channel.state == null) {
      debugPrint("Channel state is null in ChatBottomSheet");
      return const Center(child: CircularProgressIndicator());
    }
    return StreamChannel(
      channel: channel,
      child: Column(
        children: [
          Flexible(
            child: StreamMessageListView(
              errorBuilder: (context, error) {
                debugPrint("Error in message list view: $error");
                return Center(
                  child: Text(
                    'Error loading messages: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
              emptyBuilder: (context) {
                debugPrint("Message list is empty");
                return const Center(child: Text('No messages yet'));
              },
            ),
          ),
          const StreamMessageInput(),
        ],
      ),
    );
  }
}

// class ChatBottomSheet extends StatelessWidget {
//   const ChatBottomSheet({super.key, required this.channel});
//
//   final Channel channel;
//
//   @override
//   Widget build(BuildContext context) {
//     if (channel.state == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return StreamChannel(
//         channel: channel,
//         child: const Column(children: [Flexible(child: StreamMessageListView()), StreamMessageInput()]));
//   }
// }
