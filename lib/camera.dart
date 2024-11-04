import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

bool _loading = false;
String? _showing;
bool _pictureTaken = false;
String _title = "사진 찍기";
bool _audioPlaying = false;

List<String> quotes = quotes = [
  "책은 마음의 양식이다.",
  "읽지 않는 책은 읽힌 책보다 더 나쁘다. - 마르쿠스 튀리우스 키케로",
  "한 권의 책이 당신의 인생을 바꿀 수 있다. - 마야 안젤루",
  "독서는 생각의 여행이다. - 프랜시스 베이컨",
  "책을 읽는 것은 다른 사람의 생각을 여행하는 것이다. - 마르셀 프루스트",
  "좋은 책은 좋은 친구와 같다. - 아리스토텔레스",
  "독서 없는 삶은 고양이 없는 집과 같다. - 로버트 루이스 스티븐슨",
  "책은 열쇠다. - 조지 오웰",
  "독서는 자유를 가져다준다. - 에머슨",
  "책을 읽는 것은 대화하는 것이다. - 마르쿠스 튀리우스 키케로",
  "우리는 책을 통해 세계를 이해한다. - 칼 마르크스",
  "책은 영혼의 친구다. - 세네카",
  "책을 읽는 것은 삶을 확장하는 것이다. - 앤드류 카네기",
  "독서의 힘은 지식을 넘어 감성을 키운다. - 오스카 와일드",
  "독서는 사람을 만들어간다. - 헨리 데이비드 소로",
  "읽기는 무한한 세계로의 문이다. - 조지 산타야나",
  "책은 과거와 현재를 이어준다. - 미겔 드 세르반테스",
  "좋은 책은 상상력을 자극한다. - 마크 트웨인",
  "독서 습관은 인생을 변화시킨다. - 프랭클린 D. 루스벨트",
  "읽는 것이 살아가는 것이다. - 무라카미 하루키",
  "책은 우리에게 질문을 던진다. - 수잔 손탁",
  "독서로 인해 꿈이 현실이 된다. - J.K. 롤링",
  "책 속에는 모든 지혜가 담겨 있다. - 플라톤",
  "독서는 자기 발견의 여정이다. - 마리안 윌리엄슨",
  "읽는 것은 사고의 전환을 가져온다. - 에드워드 에버렛 헤일",
  "책은 우리가 가장 친한 친구가 되어준다. - 제임스 커리",
  "독서는 우리를 더 나은 사람으로 만들어준다. - 루이스 캐롤",
  "독서는 감정의 풍요로움을 더해준다. - 레프 톨스토이",
  "한 권의 책이 인생을 변화시킬 수 있다. - 헤르만 헤세",
  "읽기는 상상력을 자극한다. - 테드 창",
  "책을 읽는 것은 미래를 설계하는 것이다. - 조안 K. 롤링",
  "독서의 즐거움은 끝이 없다. - 라이너 마리아 릴케",
  "책을 통해 우리는 더 많은 삶을 경험한다. - 아나톨 프랑스",
  "독서는 혼자만의 여행이다. - 줄리안 반스",
  "한 페이지의 책이 천 개의 생각을 불러일으킨다. - 요한 볼프강 폰 괴테",
  "독서는 지식의 원천이다. - 안드레 지드",
  "책은 현실을 초월할 수 있는 힘을 준다. - 조지 루카스",
  "독서 없이는 사고할 수 없다. - 시드니 스미스",
  "책은 인간의 가장 소중한 친구다. - 마르틴 루터 킹 주니어",
  "독서는 삶의 질을 높인다. - 벤자민 프랭클린",
  "읽는 것은 인생의 맛을 더해준다. - 마이클 앙젤로",
  "책은 무한한 가능성을 열어준다. - J.R.R. 톨킨",
  "독서는 지혜의 첫걸음이다. - 소크라테스",
  "책을 읽는 것은 마음의 정원에 씨앗을 심는 것이다. - 파블로 네루다",
  "독서는 나를 풍요롭게 한다. - 헨리 포드",
  "책 속의 지혜는 무한하다. - 오르한 파묵",
  "독서는 세계를 바꾸는 힘이 있다. - 말콤 X",
  "한 권의 책이 세상을 바꿀 수 있다. - 윈스턴 처칠",
  "독서 없이는 삶이 무미건조해진다. - 알프레드 노벨",
  "책을 통해 우리는 더 나은 세상을 꿈꾼다. - 레이 브래드버리",
  "독서는 인생의 가치를 높인다. - 제임스 볼드윈"
];

int _todayCount = 0;
int _date = 0;

int _level = 5;
String text = '';
String words = '';

AudioPlayer audioPlayer = AudioPlayer();

String extracted = '';

List<String> structure_text = ['', '', '', '', '', '', '', '', '', ''];
List<Uint8List?> structure_tts = [null, null, null, null, null, null, null, null, null, null];
List<String> explain = ['', '', '', '', '', '', '', '', '', ''];
List<Uint8List?> explain_tts = [null, null, null, null, null, null, null, null, null, null];


const List<String> dropdownList = <String>['요약', '단어', '해설', '원본'];
String? dropdownValue = dropdownList.first;

Uint8List? word_tts = null;

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
    setState(() {
      _loading = false;
      _showing = null;
      _pictureTaken = false;
    });
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
      body: _pictureTaken
          ? (
            Column(
              children: [
                Text("로딩중...\n오늘 $_todayCount 개의 지문을 읽었어요!", style: TextStyle(fontSize: 10)),
                Text("${(quotes..shuffle()).first}", style: TextStyle(fontSize: 20)),
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
      floatingActionButton: _pictureTaken == false ? FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            log(image.path);

            setState(() {
              _pictureTaken = true;
              dropdownValue = dropdownList.first;
              structure_text = ['', '', '', '', '', '', '', '', '', ''];
              structure_tts = [null, null, null, null, null, null, null, null, null, null];
              explain = ['', '', '', '', '', '', '', '', '', ''];
              explain_tts = [null, null, null, null, null, null, null, null, null, null];
            });

            var ext = await ImageUploader().extractText(image.path);
            extracted = ext['text'];

            structure_text[4] = (await structureText(extracted, _level, 'structure'))['structure'];
            words = (await structureText(extracted, _level, 'word'))['word'];
            explain[4] = (await structureText(extracted, _level, 'explain'))['explain'];


            _showing = structure_text[4];

            structure_tts[4] = base64.decode((await gettingTTS(structure_text[4]))['tts']);
            explain_tts[4] = base64.decode((await gettingTTS(explain[4]))['tts']);
            word_tts = base64.decode((await gettingTTS(words))['tts']);

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
            setState(() {
              _loading = false;
              _showing = null;
              _pictureTaken = false;
            });
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ) : const Text('')
    );
  }
}


class ImageUploader {
  Future<Map<String, dynamic>> extractText(String imagePath) async {
    var url = Uri.parse("http://210.121.159.217:8765/api/literacy-extract");
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    http.StreamedResponse response = await request.send();
    http.Response res = await http.Response.fromStream(response);

    var data = jsonDecode(res.body);
    return data;
  }
}

Future<Map<String, dynamic>> structureText(String text, int level, String mode) async {
  var url = Uri.parse("http://210.121.159.217:8765/api/literacy-main");

  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({'text': text, 'level': level, 'mode': mode}),
  );

  var data = jsonDecode(response.body);

  return data;
}

Future<Map<String, dynamic>> gettingTTS(String text) async {
  var url = Uri.parse("http://210.121.159.217:8765/api/literacy-tts");

  var response = await http.post(
    url,
    headers: <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({'text': text}),
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
        onDoubleTap: () async {
          _audioPlaying = !_audioPlaying;
          if (_audioPlaying) {
            if (dropdownValue == "요약") {
              await audioPlayer.play(BytesSource(structure_tts[_level-1]!));
            } else {
              await audioPlayer.play(BytesSource(word_tts!));
            }
          } else {
            audioPlayer.stop();
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text("$_showing", style: TextStyle(fontSize: 15)),
              dropdownValue == '요약' ? FilledButton(onPressed: () async {
                setState(() {
                  _showing = '로딩중';
                });
                _level += 1;
                if (10 < _level) {
                  _level = 10;
                }
                if (structure_text[_level - 1] != '') {
                  setState(() {
                    _showing = structure_text[_level - 1];
                  });
                } else {
                  var ext = await structureText(extracted, _level, 'structure');
                  var ext_tts = await gettingTTS(ext['structure']);
                  var exp = await structureText(ext['structure'], _level, 'explain');
                  var exp_tts = await gettingTTS(exp['explain']);

                  setState(() {
                    structure_text[_level-1] = ext['structure'];
                    structure_tts[_level-1] = base64.decode(ext_tts['tts']);

                    explain[_level-1] = exp['explain'];
                    explain_tts[_level-1] = base64.decode(exp_tts['tts']);

                    _showing = structure_text[_level-1];
                  });
                }
              }, child: Text("더 길게", style: TextStyle(fontSize: 20))) : Text(''),

              dropdownValue == '요약' ? FilledButton(onPressed: () async {
                setState(() {
                  _showing = '로딩중';
                });
                _level -= 1;
                if (_level < 1) {
                  _level = 1;
                }
                if (structure_text[_level - 1] != '') {
                  setState(() {
                    _showing = structure_text[_level - 1];
                  });
                } else {
                  var ext = await structureText(extracted, _level, 'structure');
                  var ext_tts = await gettingTTS(ext['structure']);
                  var exp = await structureText(ext['structure'], _level, 'explain');
                  var exp_tts = await gettingTTS(exp['explain']);

                  setState(() {
                    structure_text[_level-1] = ext['structure'];
                    structure_tts[_level-1] = base64.decode(ext_tts['tts']);

                    explain[_level-1] = exp['explain'];
                    explain_tts[_level-1] = base64.decode(exp_tts['tts']);

                    _showing = structure_text[_level-1];
                  });
                }
              }, child: Text("더 짧게", style: TextStyle(fontSize: 20))) : Text(''),

              DropdownButton(
                value: dropdownValue,
                items: dropdownList.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 15),),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    dropdownValue = value;
                    if (dropdownValue == '요약') {
                      _showing = structure_text[_level-1];
                    } else if (dropdownValue == '단어') {
                      _showing = words;
                    } else if (dropdownValue == '해설') {
                      _showing = explain[_level-1];
                    } else if (dropdownValue == '원본') {
                      _showing = extracted;
                    }
                  });
                }),
            ],
          ),
        ),
      )
    );
  }
}
