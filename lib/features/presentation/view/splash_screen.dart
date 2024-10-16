import 'package:flutter/material.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Icon(Icons.people_sharp, size: 80)),
              SizedBox(height: 24),
              Text('GetStream Flutter Example', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      );
}