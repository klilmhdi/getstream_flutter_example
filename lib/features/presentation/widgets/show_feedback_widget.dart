import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

Future<void> showFeedbackDialog(
  BuildContext context, {
  required Call call,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.center,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FeedbackWidget(call),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class FeedbackWidget extends StatefulWidget {
  FeedbackWidget(
    this.call, {
    super.key,
  });

  Call call;

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  int value = 0;
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: SvgPicture.asset('assets/stream_logo.svg', height: 80, width: 80)),
                    const SizedBox(height: 16),
                    Text(
                      'We Value Your Feedback!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tell us about your video call experience',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...[1, 2, 3, 4, 5].map((rating) {
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              size: 40,
                              color: rating <= value ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                value = rating;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Tell us more about your experience',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                        onPressed: value > 0
                            //     ? () async {
                            //   final result =
                            //   await widget.call.collectUserFeedback(
                            //     rating: value,
                            //     reason: textController.text,
                            //   );
                            //
                            //   result.fold(success: (_) {
                            //     Navigator.pop(context);
                            //
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       const SnackBar(
                            //         content:
                            //         Text('Thank you for your feedback!'),
                            //       ),
                            //     );
                            //   }, failure: (error) {
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       SnackBar(
                            //         content: Text(
                            //             'Failed to submit feedback: $error'),
                            //       ),
                            //     );
                            //   });
                            // }
                            ? () async {}
                            : null,
                        child: const Text('Submit Feedback'))
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
