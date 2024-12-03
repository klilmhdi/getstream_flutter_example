import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget appIconAndTitleWidget(context) {
  final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Center(child: SvgPicture.asset('assets/stream_logo.svg', height: isSmallScreen ? 80 : 200, width: isSmallScreen ? 80 : 200)),
      const SizedBox(height: 20),
      Center(
          child: Text("GetStream Example",
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: CupertinoColors.black, fontWeight: FontWeight.bold))),
      const SizedBox(height: 40),
    ],
  );
}
