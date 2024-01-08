import 'dart:async';
import 'dart:io';

import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';

class ESenseConnection {
  String _deviceStatus = '';
  bool connected = false;

  late ESenseManager eSenseManager;
  final Function(double) tiltFunction;

  ESenseConnection({required eSenseDeviceName, required this.tiltFunction}) {
    eSenseManager = ESenseManager(eSenseDeviceName);
    _connectToESense();
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

      connected = false;
      switch (event.type) {
        case ConnectionType.connected:
          _deviceStatus = 'connected';
          connected = true;

          _startListenToSensorEvents();
          break;
        case ConnectionType.unknown:
          _deviceStatus = 'unknown';
          break;
        case ConnectionType.disconnected:
          _deviceStatus = 'disconnected';
          break;
        case ConnectionType.device_found:
          _deviceStatus = 'device_found';
          break;
        case ConnectionType.device_not_found:
          _deviceStatus = 'device_not_found';
          break;
      }
    });
  }

  Future<void> _connectToESense() async {
    if (!connected) {
      print('Trying to connect to eSense device...');
      connected = await eSenseManager.connect();
      print('connected: $connected');

      _deviceStatus = connected ? 'connecting...' : 'connection failed';
    }
  }

  StreamSubscription? subscription;

  void _startListenToSensorEvents() async {
    print("Setting up sensors...");
    print('start listening to sensor events...');

    // subscribe to sensor event from the eSense device
    subscription = eSenseManager.sensorEvents.listen((event) {
      print('SENSOR event: $event');
      print(event.gyro);
      if (event.gyro == null) {
        print('gyro data is not available');
        return;
      }
      double movement = event.gyro![0].abs() < 500
          ? 0
          : event.gyro![0] > 0
              ? 20
              : -20;

      if (movement != 0) {
        tiltFunction(movement);
      }
    });
  }

  void _pauseListenToSensorEvents() async {
    print('pause listening to sensor events...');

    subscription?.cancel();
  }

  void dispose() {
    _pauseListenToSensorEvents();
    eSenseManager.disconnect();
  }
}
