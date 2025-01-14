import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

/// waiting to join meeting duration
Widget waitingJoinMeetWidget(BuildContext context) => Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(20),
  ),
  padding: const EdgeInsets.all(12),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.access_time, color: Theme.of(context).primaryColor, size: 20),
      const SizedBox(width: 4),
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

/// call timer
class CallDurationTitle extends StatefulWidget {
  const CallDurationTitle({super.key, required this.call});

  final Call call;

  @override
  State<CallDurationTitle> createState() => _CallDurationTitleState();
}

class _CallDurationTitleState extends State<CallDurationTitle> {
  late DateTime _startedAt;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    widget.call.get().then((value) {
      _startedAt =
          value.foldOrNull(success: (callData) => callData.data.metadata.session.startedAt ?? DateTime.now()) ??
              DateTime.now();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _duration = DateTime.now().difference(_startedAt);
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoTheme = StreamVideoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        // color: Theme.of(context).focusColor,
        // color: Theme.of(context).highlightColor,
        // color: Theme.of(context).disabledColor,
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
              '${_duration.inMinutes.toString().padLeft(2, '0')}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: videoTheme.textTheme.title3Bold.apply(color: Colors.white)),
        ],
      ),
    );
  }
}

/// meet timer
class MeetDurationTitle extends StatefulWidget {
  const MeetDurationTitle({super.key, required this.call});

  final Call call;

  @override
  State<MeetDurationTitle> createState() => _MeetDurationTitleState();
}

class _MeetDurationTitleState extends State<MeetDurationTitle> {
  late DateTime _startedAt;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    widget.call.get().then((value) {
      _startedAt =
          value.foldOrNull(success: (callData) => callData.data.metadata.session.startedAt ?? DateTime.now()) ??
              DateTime.now();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _duration = DateTime.now().difference(_startedAt);
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoTheme = StreamVideoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).focusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 4),
          Text(
              '${_duration.inMinutes.toString().padLeft(2, '0')}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: videoTheme.textTheme.title3Bold.apply(color: Colors.white)),
        ],
      ),
    );
  }
}

/// livestream timer
class LivestreamTimer extends StatefulWidget {
  final DateTime? startedAt;

  const LivestreamTimer({super.key, required this.startedAt});

  @override
  _LivestreamTimerState createState() => _LivestreamTimerState();
}

class _LivestreamTimerState extends State<LivestreamTimer> {
  late Timer _durationTimer;
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(Duration.zero);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final now = DateTime.now();
    final startedAt = widget.startedAt ?? now;
    _duration.value = now.difference(startedAt);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration.value = _duration.value + const Duration(seconds: 1);
    });
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _duration,
      builder: (context, duration, _) {
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        final formattedDuration = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 4,
            ),
            const SizedBox(width: 8),
            Text(
              formattedDuration,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}