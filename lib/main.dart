import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'game.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:flame/game.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIPL Physics client',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const MyHomePage(title: 'SIPL Physics client'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int appState = 2;
  String jsonPath = '';
  bool isImageChosen = false;
  Image? _chosenImage;
  File? _chosenImageFile;
  TextEditingController ipEditingController =
      TextEditingController(text: '132.68.58.30');
  TextEditingController userEditingController =
      TextEditingController(text: 'adam');
  TextEditingController passEditingController =
      TextEditingController(text: '318758489');

  @override
  Widget build(BuildContext context) {
    Widget spinkit = SpinKitWave(
      //color: Colors.white,
      size: 100.0,
      itemBuilder: (BuildContext context, int index) => DecoratedBox(
        decoration: BoxDecoration(
            //image: DecorationImage(image: AssetImage('assets/images/sipl.jpg'))
            color: index.isEven
                ? const Color.fromARGB(78, 16, 92, 207)
                : const Color.fromARGB(78, 16, 92, 207)),
      ),
    );
    if (appState == 0) {
      return Container(
        color: Colors.white,
        child: Container(
            child: spinkit,
            decoration: const BoxDecoration(
                // color: Colors.white,
                image: DecorationImage(
                    image: AssetImage('assets/images/sipl.jpg')))),
      );
      //return spinkit;
    } else if (appState == 1) {
      return GameWidget(game: MyGame(jsonPath));
    } else {
      return Scaffold(
        body: Container(
            alignment: Alignment.topCenter,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Flexible(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Transform(
                  //   alignment: Alignment.center,
                  //   transform:
                  //       Matrix4.rotationY(math.pi * (isImageChosen ? 1 : 0)),
                  //   child: Image(
                  //       image: currentImage.image,
                  //       alignment: Alignment.topLeft,
                  //       fit: BoxFit.contain),
                  // ),
                  currentImage,
                  const Spacer(),
                  Container(
                      constraints: const BoxConstraints(maxWidth: 150),
                      alignment: Alignment.topRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Flexible(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.green,
                                    onPrimary: Colors.white,
                                    shadowColor: Colors.greenAccent,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(32.0)),
                                  ),
                                  onPressed: () {
                                    chooseImage(ImageSource.gallery);
                                    isImageChosen = true;
                                  },
                                  child: const Text('Gallery'),
                                ),
                                //const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.blue,
                                      onPrimary: Colors.white,
                                      shadowColor: Colors.greenAccent,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32.0))),
                                  onPressed: () {
                                    chooseImage(ImageSource.camera);

                                    isImageChosen = true;
                                  },
                                  child: const Text('Camera'),
                                ),
                                //const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.purple,
                                      onPrimary: Colors.white,
                                      shadowColor: Colors.greenAccent,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32.0))),
                                  onPressed: runGame,
                                  child: const Text('Exctract circuit'),
                                ),
                              ])),
                          const Image(
                              image: AssetImage('assets/images/sipl.jpg'))
                        ],
                      )),
                ]))),
      );
    }
  }

  Image get currentImage {
    return _chosenImage ?? Image.asset('assets/images/no_image.jpg');
  }

  File get currentFile {
    return _chosenImageFile ?? File('EMPTY FILE');
  }

  void chooseImage(var source) async {
    final ImagePicker _picker = ImagePicker();
    if (source == ImageSource.gallery ||
        await Permission.camera.request().isGranted) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        _chosenImage = Image.file(File(image.path));
        _chosenImageFile = File(image.path);
      }
    }
    setState(() {});
  }

  void runGame() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (isImageChosen) {
      setState(() {
        appState = 0;
      });
      await sendImage();
      //jsonPath = await downloadJson();
      setState(() {
        appState = 2;
      });
    } else {
      AlertDialog alert = AlertDialog(
        title: const Text("Error!"),
        content: const Text("Choose image or take photo"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }

  Future<String> downloadJson() async {
    FTPConnect ftpConnect = FTPConnect(ipEditingController.text,
        user: userEditingController.text,
        pass: passEditingController.text,
        port: 2121);
    File file = File('EMPTY FILE');
    try {
      await Permission.storage.request();
      await ftpConnect.connect();
      String fileName = 'output.json';
      final Directory directory = await getApplicationDocumentsDirectory();
      file = File('${directory.path}/$fileName');
      await ftpConnect.downloadFileWithRetry(fileName, file);
      await ftpConnect.disconnect();
    } catch (e) {
      AlertDialog alert = AlertDialog(
        title: const Text("Error!"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
    FocusScope.of(context).requestFocus(FocusNode());
    return file.path;
  }

  Future<void> sendImage() async {
    FTPConnect ftpConnect = FTPConnect(ipEditingController.text,
        user: userEditingController.text,
        pass: passEditingController.text,
        port: 2121);
    try {
      await ftpConnect
          .connect()
          .then((value) => ftpConnect.uploadFile(currentFile))
          .then((value) => ftpConnect.disconnect());
    } catch (e) {
      AlertDialog alert = AlertDialog(
        title: const Text("Error!"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
