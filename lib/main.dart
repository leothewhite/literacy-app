import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:literacy/camera.dart';
import 'package:literacy/tutorial.dart';

late List<CameraDescription> cameras;
late CameraDescription firstCamera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  firstCamera = cameras.first;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '긴 글을 읽기 힘든 사회적 약자들을 위한 앱(이런식으로 바꿔)'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
                onPressed: () {
                  log("pushed");
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return TakePictureScreen(camera: firstCamera);
                    }
                  ));
                },
                child: const Text(
                  "사진찍기"
                )
            ),
            FilledButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return TutorialScreen();
                      }
                  ));
                },
                child: const Text(
                    "앱 사용법"
                )
            ),
          ],
        ),
      ),
    );
  }
}
