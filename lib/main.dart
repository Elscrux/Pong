import 'dart:async';
import 'dart:io';

import 'package:esense_flutter/esense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_todo_example/widgets/line_chart.dart';
import 'package:permission_handler/permission_handler.dart';

import 'game/game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ESenseApp());
}

class ESenseApp extends StatefulWidget {
  const ESenseApp({Key? key}) : super(key: key);

  @override
  ESenseState createState() => ESenseState();
}

class ESenseState extends State<ESenseApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _time = '';
  List<int> _gyro = [0, 0, 0];
  String _directionX = '';
  String _directionY = '';
  String _directionZ = '';
  String _acc = '';
  String _button = 'not pressed';
  bool connected = false;

  final List<int> _gyroX = [];
  final List<int> _gyroY = [];
  final List<int> _gyroZ = [];
  late PongGame pongGame;

  // the name of the eSense device to connect to -- change this to your own device.
  // String eSenseName = 'eSense-0164';
  static const String eSenseDeviceName = 'eSense-0091';

  // todo add popup to select name
  ESenseManager eSenseManager = ESenseManager(eSenseDeviceName);

  @override
  void initState() {
    super.initState();
    pongGame = PongGame();
    _listenToESense();
  }

  Future<void> _askForPermissions() async {
    print('asking for permissions...');
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      print('bluetooth permission granted!');
    } else {
      print(
          'WARNING - no permission to use Bluetooth granted. Cannot access eSense device.');
    }
    // for some strange reason, Android requires permission to location for Bluetooth to work.....?
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        print(
            'WARNING - no permission to access location granted. Cannot access eSense device.');
      } else {
        print('location permission granted!');
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    // if you want to get the connection events when connecting,
    // set up the listener BEFORE connecting...
    eSenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            connected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            sampling = false;
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });
  }

  Future<void> _connectToESense() async {
    if (!connected) {
      print('Trying to connect to eSense device...');
      connected = await eSenseManager.connect();
      print('connected: $connected');

      setState(() {
        _deviceStatus = connected ? 'connecting...' : 'connection failed';
      });
    }
  }

  void _listenToESenseEvents() async {
    eSenseManager.eSenseEvents.listen((event) {
      // print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage ?? -1;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            // TODO
            break;
          case AdvertisementAndConnectionIntervalRead:
            // TODO
            break;
          case SensorConfigRead:
            // TODO
            break;
        }
      });
    });

    // _getESenseProperties();
  }

  // void _getESenseProperties() async {
  //   // get the battery level every 10 secs
  //   Timer.periodic(
  //     const Duration(seconds: 10),
  //         (timer) async =>
  //     (connected) ? await eSenseManager.getBatteryVoltage() : null,
  //   );
  //
  //   // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
  //   // it seems like the eSense BTLE interface does NOT like to get called
  //   // several times in a row -- hence, delays are added in the following calls
  //   Timer(const Duration(seconds: 2),
  //           () async => await eSenseManager.getDeviceName());
  //   Timer(const Duration(seconds: 3),
  //           () async => await eSenseManager.getAccelerometerOffset());
  //   Timer(
  //       const Duration(seconds: 4),
  //           () async =>
  //       await eSenseManager.getAdvertisementAndConnectionInterval());
  //   Timer(const Duration(seconds: 15),
  //           () async => await eSenseManager.getSensorConfig());
  // }

  void toggleSampling() {
    if (sampling) {
      _pauseListenToSensorEvents();
    } else {
      _startListenToSensorEvents();
    }
  }

  StreamSubscription? subscription;

  void _startListenToSensorEvents() async {
    // // any changes to the sampling frequency must be done BEFORE listening to sensor events
    // print('setting sampling frequency...');
    // await eSenseManager.setSamplingRate(10);

    print("Setting up sensors...");
    setState(() {
      sampling = true;
    });
    print('start listening to sensor events...');

    // subscribe to sensor event from the eSense device
    subscription = eSenseManager.sensorEvents.listen((event) {
      print('SENSOR event: $event');
      print(event.gyro);
      if (event.gyro == null) {
        print('gyro data is not available');
        return;
      }
      setState(() {
        _time = '${event.timestamp} ${event.packetIndex}';
        _gyro = event.gyro!;

        // > 0 = left
        // < 0 = right
        _directionX = event.gyro![0].abs() < 500
            ? 'no motion'
            : event.gyro![0] > 0
                ? 'left'
                : 'right';
        _gyroX.add(event.gyro![0]);
        if (_gyroX.length > 100) {
          _gyroX.removeAt(0);
        }

        // about -200 is the center apparently
        pongGame.tilt((_gyro[0] + 200) * 0.001);

        _directionY = event.gyro![1].abs() < 500
            ? 'no motion'
            : event.gyro![1] > 0
                ? 'forward'
                : 'backward';
        _gyroY.add(event.gyro![1]);
        if (_gyroY.length > 100) {
          _gyroY.removeAt(0);
        }

        _directionZ = event.gyro![2].abs() < 500
            ? 'no motion'
            : event.gyro![2] > 0
                ? 'forward'
                : 'backward';
        _gyroZ.add(event.gyro![2]);
        if (_gyroZ.length > 100) {
          _gyroZ.removeAt(0);
        }

        _acc = event.accel.toString();
      });
    });
    setState(() {
      sampling = true;
    });
  }

  void _pauseListenToSensorEvents() async {
    print('pause listening to sensor events...');

    subscription?.cancel();
    setState(() {
      sampling = false;
    });
  }

  @override
  void dispose() {
    _pauseListenToSensorEvents();
    eSenseManager.disconnect();
    super.dispose();
  }

  String toSize(int n, int size) {
    var fullString = n.toString();
    var numberString = (n < 0) ? fullString.substring(1) : fullString;
    var prefixString = (n < 0) ? "-" : "";

    var len = fullString.length;
    if (len == size) {
      return fullString;
    } else if (len < size) {
      return prefixString + '0' * (size - len) + numberString;
    } else {
      return prefixString + numberString.substring(len - size) + ('.' * 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pong'),
        ),
        body: Align(
          alignment: Alignment.topLeft,
          child: ListView(
            children: [
              Text('eSense Device Status: \t$_deviceStatus'),
              Text('eSense Device Name: \t$_deviceName'),
              Text('eSense Battery Level: \t$_voltage'),
              Text('eSense Button Event: \t$_button'),
              const Text(''),
              Text("Time: $_time"),
              Text("Gyro X: ${_gyro[0]}"),
              Text("Gyro Y: ${_gyro[1]}"),
              Text("Gyro Z: ${_gyro[2]}"),
              Text("Acc: $_acc"),
              Container(
                height: 80,
                width: 200,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextButton.icon(
                  onPressed: _connectToESense,
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'CONNECT....',
                    style: TextStyle(fontSize: 35),
                  ),
                ),
              ),
              Text("DirectionX: $_directionX"),
              SizedBox(
                height: 250,
                width: 400,
                child: ESenseLineChart(
                  // Pass your data here
                  _gyroX
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                      .toList(),
                ),
              ),
              // Text("DirectionY: $_directionY"),
              // SizedBox(
              //   height: 250,
              //   width: 400,
              //   child: MyLineChart(
              //     // Pass your data here
              //     _gyroY
              //         .asMap()
              //         .entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
              //         .toList(),
              //   ),
              // ),
              // Text("DirectionZ: $_directionZ"),
              // SizedBox(
              //   height: 250,
              //   width: 400,
              //   child: MyLineChart(
              //     // Pass your data here
              //     _gyroZ
              //         .asMap()
              //         .entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
              //         .toList(),
              //   ),
              // ),
              SizedBox(
                  height: 800, width: 400, child: GameWidget(game: pongGame))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          // a floating button that starts/stops listening to sensor events.
          // is disabled until we're connected to the device.
          onPressed: (eSenseManager.connected)
              ? (sampling)
                  ? _pauseListenToSensorEvents
                  : _startListenToSensorEvents
              : null,
          tooltip: 'Listen to eSense sensors',
          child: (!sampling)
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
        ),
      ),
    );
  }
}
