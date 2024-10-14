import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget basicButton(
        {required String title,
        required VoidCallback function,
        double width = double.infinity,
        double radius = 8,
        double fontSize = 20.0,
        Color color = Colors.deepPurple}) =>
    SizedBox(
        width: width,
        height: 60.0,
        child: ElevatedButton(
            onPressed: function,
            style: ButtonStyle(
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
                animationDuration: const Duration(seconds: 12),
                splashFactory: InkRipple.splashFactory,
                overlayColor: WidgetStateProperty.all(CupertinoColors.white.withOpacity(0.20)),
                backgroundColor: WidgetStateProperty.all(color)),
            child: Center(
                child: Text(title,
                    style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)))));
