import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class CallDurationTitle extends StatefulWidget {
  const CallDurationTitle({
    super.key,
    required this.call,
    required this.onJoinCall,
  });

  final Call call;
  final Future<bool> Function() onJoinCall;

  @override
  State<CallDurationTitle> createState() => _CallDurationTitleState();
}

class _CallDurationTitleState extends State<CallDurationTitle> {
  late DateTime _startedAt;
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isCallStarted = false;

  @override
  void initState() {
    super.initState();

    widget.onJoinCall().then((isJoined) {
      if (isJoined) {
        setState(() {
          _isCallStarted = isJoined == true;
        });
        _startedAt = DateTime.now();

        // Start the timer to update call duration
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          setState(() {
            _duration = DateTime.now().difference(_startedAt);
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            _isCallStarted
                ? '${_duration.inMinutes.toString().padLeft(2, '0')}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                : 'Waiting for participant...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}

class WaitingJoinMeetWidget extends StatelessWidget {
  const WaitingJoinMeetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Waiting for participant...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
//
// class CallDurationTitle extends StatefulWidget {
//   const CallDurationTitle({
//     super.key,
//     required this.call,
//   });
//
//   final Call call;
//
//   @override
//   State<CallDurationTitle> createState() => _CallDurationTitleState();
// }
//
// class _CallDurationTitleState extends State<CallDurationTitle> {
//   DateTime? _startedAt;
//   Duration _duration = Duration.zero;
//   Timer? _timer;
//   StreamSubscription<CallState>? _callStateSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Listen to call state updates
//     _callStateSubscription = widget.call.state.listen((callState) {
//       _handleCallStateUpdate(callState);
//     });
//
//     // Fetch the initial call state
//     _handleCallStateUpdate(widget.call.state.value);
//   }
//
//   void _handleCallStateUpdate(CallState? callState) {
//     if (callState == null) return;
//
//     /// if any problem happened, return here and change startAt value
//     final startedAt = DateTime.now();
//     debugPrint("Call startedAt value: $startedAt");
//
//     if ((_startedAt == null || _startedAt != startedAt)) {
//       setState(() {
//         _startedAt = startedAt;
//         _startTimer();
//       });
//     }
//   }
//
//   void _startTimer() {
//     _timer?.cancel();
//
//     if (_startedAt == null) return;
//
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//
//       setState(() {
//         _duration = DateTime.now().difference(_startedAt!);
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _callStateSubscription?.cancel();
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.access_time, color: Theme.of(context).primaryColor, size: 20),
//           const SizedBox(width: 8),
//           Text(
//             _startedAt != null
//                 ? '${_duration.inMinutes.toString().padLeft(2, '0')}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
//                 : 'Waiting for participant...',
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

///

// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:getstream_flutter_example/core/utils/consts/assets.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';
//
// class CallDurationTitle extends StatefulWidget {
//   const CallDurationTitle({super.key, required this.call});
//
//   final Call call;
//
//   @override
//   State<CallDurationTitle> createState() => _CallDurationTitleState();
// }
//
// class _CallDurationTitleState extends State<CallDurationTitle> {
//   late DateTime _startedAt;
//   Duration _duration = Duration.zero;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//
//     widget.call.get().then((value) {
//       _startedAt =
//           value.foldOrNull(success: (callData) => callData.data.metadata.session.startedAt ?? DateTime.now()) ??
//               DateTime.now();
//
//       _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }
//
//         setState(() {
//           _duration = DateTime.now().difference(_startedAt);
//         });
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final videoTheme = StreamVideoTheme.of(context);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).scaffoldBackgroundColor,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       padding: const EdgeInsets.all(10),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SvgPicture.asset(shieldCheck, width: 20),
//           const SizedBox(width: 8),
//           Text(
//               '${_duration.inMinutes.toString().padLeft(2, '0')}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
//               style: videoTheme.textTheme.title3.apply(color: Colors.black87)),
//         ],
//       ),
//     );
//   }
// }
