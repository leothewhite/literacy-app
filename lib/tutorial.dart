import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


Future<void> main() async{
  runApp(TutorialScreen());
}

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("앱 사용법"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("튜토리얼 내용들...")
          ],
        ),
      ),
    );
  }
}