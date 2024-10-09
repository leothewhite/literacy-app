import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// flag 변수들
bool _loading = false;
String? _showingMenu;
bool _pictureTaken = false;
String _title = "사진 찍기";
bool _audioPlaying = false;

// 칭찬 기능 날짜별로 카운트
int _todayCount = 0;
int _date = 0;


AudioPlayer audioPlayer = AudioPlayer();

// 요약된 것들
Map<String, String> results = {'summary': '', 'original': '', 'oneline': '', 'meaning': ''};

// tts 오디오
Map<String, Uint8List?> tts = {'summary': null, 'original': null, 'oneline': null, 'meaning': null};

const List<String> dropdownList = <String>['한 줄 요약', '요약', '원문', '단어 설명'];

// if문을 줄이기 위함
Map menuJsonMatch = {'요약': 'summary', '원문': 'original', '한 줄 요약': 'oneline', '단어 설명': 'meaning'};


String? dropdownValue = dropdownList.first;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  audioPlayer.setReleaseMode(ReleaseMode.stop);

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
      // 타이틀바 설정
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
            Column(
              children: [
                Text("로딩중...\n오늘 $_todayCount 개의 지문을 읽었어요!"),
                Container(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                )
              ]

            )
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
            var resp = await ImageUploader().uploadImage(image.path);
            results['summary'] = resp[0];
            results['original'] = resp[1];
            results['oneline'] = resp[2];
            results['meaning'] = resp[3];

            // TTS 전달받은 값 base64 decode 후 저장
            Map<String, dynamic> ttsEncoded = await gettingTTS(results);

            ttsEncoded.forEach((k,v) {
              tts[k] = base64.decode(v);
            });

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

Future<Map<String, dynamic>> gettingTTS(Map<String, String> texts) async {
  var url = Uri.parse("http://210.121.159.217:8765/api/literacy-tts");

  var response = await http.post(
    url,
    headers: <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(texts), // 요약 등의 결과값
  );

  if (response.statusCode == 200) {
    log('Success!');
  } else {
    log('Failed: ${response.statusCode}');
  }
  
  var ttsFiles = jsonDecode(response.body);
  
  return ttsFiles;
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
      body: GestureDetector(
        // 두 번 클릭하면 오디오 재생, 다시 두 번 클릭하면 오디오 정지
        onDoubleTap: () async {
          _audioPlaying = !_audioPlaying;
          if (_audioPlaying) {
            await audioPlayer.play(BytesSource(tts[menuJsonMatch[dropdownValue]]!));
          } else {
            audioPlayer.stop();
          }
        },
        child: SingleChildScrollView(
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
      )
    );
  }
}