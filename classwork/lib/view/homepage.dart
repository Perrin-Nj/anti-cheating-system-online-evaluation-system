import 'package:camera/camera.dart';
import 'package:classwork/main.dart';
import 'package:flutter/material.dart';

import 'package:tflite/tflite.dart';

import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_helper.dart';
import 'package:another_flushbar/flushbar_route.dart';
//import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraImage? cameraImage;
  CameraController? cameraController;
  int teachingAttempts = 1;
  //final FlutterTts flutterTts = FlutterTts();

  String output = '';
  int outputOccurence = 0;
  List<int> appActivity = [];
  ValueNotifier<int> dialogTrigger = ValueNotifier(0);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        setState(() {
          appActivity[1] = appActivity[1] + 1;
        });

        break;
      case AppLifecycleState.paused:
        print("app in paused");
        setState(() {
          appActivity[2] = appActivity[2] + 1;
        });

        break;
      case AppLifecycleState.detached:
        print("app in detached");
        setState(() {
          appActivity[3] = appActivity[3] + 1;
        });

        break;
    }
  }

  loadCamera() {
    cameraController = CameraController(cameras![1], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            runModel();
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Classwork, anti-cheating-system'),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 0.3,
                child: !cameraController!.value.isInitialized
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameraController!.value.aspectRatio,
                        child: CameraPreview(cameraController!),
                      ),
              ),
            ),
          ),
          //   Text("${appActivity[2]}"),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const Text(
                "Cheating detection: ",
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    backgroundColor: Colors.blue),
              ),
              output == "0 Cheating"
                  ? Text(
                      "You are cheating. please, focus on the camera, or on your script. 'The cheating occurence  -> $outputOccurence'",
                      style: const TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          backgroundColor: Colors.yellow),
                    )
                  : const Text(
                      "Good, you ain't cheating, keep this up ",
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        backgroundColor: Colors.green,
                      ),
                    ),
            ],
          ),

          outputOccurence > 300
              ? AlertDialog(
                  title: const Text('Cheating attempts'),
                  content: Text(
                      "We've detected a teaching attempt.\nPlease, focus on your script, or on the camera. Be careful henceforth\n\nTotal cheating attempts: $teachingAttempts."),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        outputOccurence = 0;
                        teachingAttempts = teachingAttempts + 1;
                      },
                    ),
                  ],
                )
              : Text(""),
        ],
      ),
    );
  }

  void runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map(
          (plane) {
            return plane.bytes;
          },
        ).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.3,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      predictions!.forEach((element) {
        setState(() {
          output = element['label'];
          if (output == "0 Cheating") {
            outputOccurence = outputOccurence + 1;
          }
        });

        /*  if (outputOccurence >= 2) {
          Flushbar(
                  shouldIconPulse: true,
                  flushbarStyle: FlushbarStyle.GROUNDED,
                  flushbarPosition: FlushbarPosition.TOP,
                  message: "You have one more attempt to cheating")
              .show(context);
        }*/
      });

      // await tfl.Interpreter.fromAsset('assets/model_unquant.tflite');
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }
}
