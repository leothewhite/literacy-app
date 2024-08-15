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

const List<String> list = <String>['요약', '하이라이트 표시'];

List<String> bold_list = [];

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
        }) : Text("잘 하고 있어요!"),
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

            List resp = await ImageUploader().uploadImage(image.path);

            setState(() {
              _loading = false;
              if (dropdownValue == '요약') {
                _showing = resp[0];
              } else {
                _showing = resp[0];
                bold_list = resp[1]!.split(' ');
                log(bold_list.length.toString());
                for (String b in bold_list) {
                  log(b);
                }
              }
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
    return [data['summary'], data['bold']];
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
      body: Center(
        child: Column(
          children: <Widget>[
            _loading ? Text("잘 하고 있어요!") : (
              dropdownValue == "요약" ?
                Text("$_showing")
              : EasyRichText(
                "$_showing",
                patternList: bold_list.map<EasyRichTextPattern>((String value) {
                  return EasyRichTextPattern (
                    targetString: value,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                }).toList(),
              )
            ),
            DropdownButton(
              onChanged: (String? value) {
                setState(() {
                  dropdownValue = value;
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