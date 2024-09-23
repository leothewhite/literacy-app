import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// flag 변수들
bool _loading = false;
String? _showingMenu;
bool _pictureTaken = false;
String _title = "사진 찍기";

// 칭찬 기능 날짜별로 카운트
int _todayCount = 0;
int _date = 0;

List results = ["에러: 로딩이 되지 않았습니다.", "에러: 로딩이 되지 않았습니다."];

const List<String> dropdownList = <String>['한 줄 요약', '요약', '원문', '단어 설명'];

// if문을 줄이기 위함
Map menuJsonMatch = {'요약': 0, '원문': 1, '한 줄 요약': 2, '단어 설명': 3};

String? dropdownValue = dropdownList.first;

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
  // 카메라 처리
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
    log("$_loading $_pictureTaken");
    setState(() {
      if (_pictureTaken == false) {
        _title = "사진 찍기";
      } else {
        _title = "불러오는 중...";
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text("$_title")),
      // 사진을 찍었다면 로딩메뉴, 찍지 않았다면 카메라 화면
      body: _pictureTaken
          ? (
            Text("로딩중...\n오늘 $_todayCount 개의 지문을 읽었어요!")
          )
          : FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      floatingActionButton: FloatingActionButton(
        // 촬영 버튼을 누른 후 동작
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            log(image.path);

            setState(() {
              _pictureTaken = true;
            });

            // 이미지 업로드 후 요약 등의 결과
            results = await ImageUploader().uploadImage(image.path);

            _showingMenu = results[menuJsonMatch[dropdownValue]];

            // 칭찬 기능 위해 카운트
            setState(() {
              if (DateTime.now().day == _date) {
                ++_todayCount;
              } else {
                _date = DateTime.now().day;
                _todayCount = 1;
              }
              _loading = true;
            });

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                ),
              ),
            );
            // flag 변수들 재설정
            setState(() {
              _loading = false;
              _showingMenu = null;
              _pictureTaken = false;
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
  // 이미지 서버에 업로드 후 response 받아오기
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
      appBar: AppBar(title: const Text("결과")),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text("$_showingMenu"),
            // 드랍다운 메뉴 설정에 따라 본문 바뀌게 하기
            DropdownButton(
              onChanged: (String? value) {
                setState(() {
                  dropdownValue = value;
                  _showingMenu = results[menuJsonMatch[dropdownValue]];
                });
              },
              value: dropdownValue,
              items: dropdownList.map<DropdownMenuItem<String>>((String value) {
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