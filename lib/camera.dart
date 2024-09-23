import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_rich_text/easy_rich_text.dart';

bool _loading = true;
String? _showing;
bool _taken = false;
int _today = 0;
int _date = 0;
List resp = ["에러: 로딩이 되지 않았습니다.", "에러: 로딩이 되지 않았습니다."];

const List<String> list = <String>['한 줄 요약', '요약', '원문', '단어 설명'];

Map foring = {'요약': 0, '원문': 1, '한 줄 요약': 2, '단어 설명': 3};


String? dropdownValue = list.first;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;


  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;



  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: !_taken ? FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        }) : Text("로딩중...\n오늘 ${_today} 개의 지문을 읽었어요!"),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            log(image.path);

            setState(() {
              _taken = true;
            });

            resp = await ImageUploader().uploadImage(image.path);

            _showing = resp[foring[dropdownValue]];

            setState(() {
              if (DateTime.now().day == _date) {
                ++_today;
              } else {
                _date = DateTime.now().day;
                _today = 1;
              }

              _loading = false;
            });

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                ),
              ),
            );
            setState(() {
              _loading = true;
              _showing = null;
              _taken = false;
            });
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}



class ImageUploader {
  Future<List> uploadImage(String imagePath) async {
    var url = Uri.parse("http://210.121.159.217:8765/api/literacy");
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    http.StreamedResponse response = await request.send();
    http.Response res = await http.Response.fromStream(response);

    var data = jsonDecode(res.body);
    return [data['summary'], data['original'], data['oneline'], data['meaning']];
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => DisplayPictureScreenState();

}

class DisplayPictureScreenState extends State<DisplayPictureScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _loading ? Text("로딩중...\n오늘 ${_today} 개의 지문을 읽었어요!") : (
            dropdownValue == "요약" ?
              Text("$_showing")
            : Text("$_showing")
            ),
            DropdownButton(
              onChanged: (String? value) {
                setState(() {
                  dropdownValue = value;
                  _showing = resp[foring[dropdownValue]];
                });
              },
              value: dropdownValue,
              items: list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            )
          ],
        ),
      ),
    );
  }
}