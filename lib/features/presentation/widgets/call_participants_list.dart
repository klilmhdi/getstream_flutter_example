import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class CallParticipantsList extends StatelessWidget {
  const CallParticipantsList({super.key, required this.call, this.scrollController});

  final Call call;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final streamVideoTheme = StreamVideoTheme.of(context);
    final textTheme = streamVideoTheme.textTheme;

    return StreamBuilder<CallState>(
      stream: call.state.asStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final callState = snapshot.data!;
        final participants = callState.callParticipants;

        return Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: CupertinoColors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Participants (${participants.length})',
                      style: textTheme.title3.apply(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: ShareCallCard(
              //     callId: call.id,
              //   ),
              // ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController, // Use the passed scroll controller
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          StreamUserAvatarTheme(
                            data: streamVideoTheme.userAvatarTheme,
                            child: StreamUserAvatar(
                              user: UserInfo(
                                id: participant.userId,
                                name: participant.name.ifEmpty(() => participant.userId),
                                image: participant.image,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: CupertinoColors.white),
                                  ),
                                  Text(
                                    participant.roles.join(', '),
                                    style: textTheme.footnoteItalic,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          participant.isAudioEnabled
                              ? const Icon(Icons.mic_rounded, color: CupertinoColors.white)
                              : const Icon(Icons.mic_off_rounded, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          participant.isVideoEnabled
                              ? const Icon(Icons.videocam_rounded, color: CupertinoColors.white)
                              : const Icon(Icons.videocam_off_rounded, color: Colors.redAccent),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
