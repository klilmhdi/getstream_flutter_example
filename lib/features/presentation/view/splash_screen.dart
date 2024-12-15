import 'package:flutter/material.dart';

import '../widgets/app_title_and_icon_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: appIconAndTitleWidget(context),
      ),
    );
  }
}
