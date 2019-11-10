import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import './settings.dart';
import './bluetooth.dart';

GetIt getIt = GetIt.instance;

class BluetoothConnect extends StatelessWidget {
  final bluetooth = getIt.get<BluetoothController>();
  final snackbar = getIt.get<SnackbarController>();

  BluetoothConnect({Key key, String deviceName}) : super(key: key) {
    bluetooth.setTargetDeviceName(deviceName);
  }

  @override
  Widget build(BuildContext context) {
    snackbar.stream.listen(
      (snack) {
        if (snack != null) {
          Scaffold.of(context).showSnackBar(snack);
        }
      },
    );

    return StreamBuilder<int>(
      stream: bluetooth.stream,
      initialData: 1,
      builder: (c, snapshot) {
        if (snapshot.data == 1) {
          return IconButton(
            icon: Icon(Icons.bluetooth),
            iconSize: 32,
            onPressed: () => bluetooth.startScan(),
          );
        } else if (snapshot.data == 2) {
          return IconButton(
            icon: Icon(Icons.bluetooth_searching),
            iconSize: 32,
            onPressed: () => bluetooth.stopScan(),
          );
        } else if (snapshot.data == 3) {
          return IconButton(
            icon: Icon(Icons.bluetooth_connected),
            iconSize: 32,
            onPressed: () => bluetooth.disconnect(),
          );
        } else {
          return IconButton(
            icon: Icon(Icons.bluetooth_disabled),
            iconSize: 32,
            onPressed: () => bluetooth.showSnackbar(
                Icons.bluetooth_disabled, 'Turn on Bluetooth!'),
          );
        }
      },
    );
  }
}

class SnackbarController {
  BehaviorSubject<Widget> _controller;
  String _lastMsg = "";

  SnackbarController() {
    _controller = BehaviorSubject.seeded(null);
  }

  Observable<Widget> get stream => _controller.stream;
  Widget get current => _controller.value;

  openSnackbar(Widget widget, String msg) {
    if (msg != _lastMsg) {
      _lastMsg = msg;
      _controller.add(widget);
    }
  }
}

class BluetoothConnector {
  final settings = getIt.get<ConfigNameController>();
  final snackbar = getIt.get<SnackbarController>();

  BehaviorSubject<int> _controller = BehaviorSubject.seeded(0);

  BluetoothDevice device;
  String targetDeviceName;

  bool isBtAvalible = false;
  bool isScanning = false;
  bool isConnected = false;
  bool isWriting = false;

  List<MapEntry<String, List<int>>> msgStack = List();
  HashMap<String, BluetoothCharacteristic> map;

  sendInit() async {}

  BluetoothConnector() {
    settings.stream.listen((data) {
      targetDeviceName = data;
    });
    initDevice();
  }

  Observable<int> get stream => _controller.stream;
  int get current => _controller.value;

  startScan() async {
    if (!isScanning) {
      (await FlutterBlue.instance.connectedDevices).forEach((connected) {
        print('Connected: ${connected.name}');
        setDevice(connected);
      });
      FlutterBlue.instance.startScan(timeout: Duration(seconds: 16));
    }
  }

  stopScan() async {
    if (isScanning) {
      FlutterBlue.instance.stopScan();
    }
  }

  disconnect() async {
    if (device != null) {
      showSnackbar(Icons.bluetooth_disabled, 'Disonnected from ${device.name}');
      device.disconnect();

      map = null;
      device = null;
      isConnected = false;
      isScanning = false;

      calcState();
    }
  }

  setTargetDeviceName(String name) {
    targetDeviceName = name;
  }

  Future<void> initDevice() async {
    FlutterBlue.instance.state.listen((data) {
      bool isAvalible = (data == BluetoothState.on);
      isBtAvalible = isAvalible;
      if (isAvalible) {
        // showSnackbar(Icons.bluetooth, 'Bluetooth is online again!');
      }
      calcState();
    });

    FlutterBlue.instance.isScanning.listen((data) {
      isScanning = data;
      print(isScanning);
      calcState();
    });

    (await FlutterBlue.instance.connectedDevices).forEach((connected) {
      print('Connected: ${connected.name}');
      setDevice(connected);
    });
    FlutterBlue.instance.scanResults.listen((scans) {
      for (var scan in scans) {
        setScanResult(scan);
      }
    });
  }

  void calcState() {
    int stage = 1; // waiting for scanning
    stage = (isScanning) ? 2 : stage; // searching
    stage = (isConnected) ? 3 : stage; // connected
    stage = (!isBtAvalible) ? 0 : stage; // not avalible
    print(stage);
    _controller.add(stage);
  }

  Future<void> setScanResult(ScanResult scan) async {
    BluetoothDevice _device = scan.device;
    await setDevice(_device);
  }

  Future<void> setDevice(BluetoothDevice _device) async {
    if (_device.name == targetDeviceName && device == null) {
      print(_device.name);

      await _device.disconnect();
      await _device.connect();

      map = new HashMap<String, BluetoothCharacteristic>();

      showSnackbar(Icons.bluetooth, 'Connected to ${_device.name}');
      device = _device;
      isConnected = true;
      calcState();

      List<BluetoothService> services = await _device.discoverServices();

      for (var service in services) {
        for (var c in service.characteristics) {
          map[c.uuid.toString()] = c;
          print('${c.serviceUuid} ${c.uuid} found!');
        }
      }

      await sendInit();
    }
  }

  Future<List<int>> readService(String characteristicGuid) async {
    if (map != null) {
      var characteristic = map[characteristicGuid];
      print(map);
      if (characteristic != null) {
        return await characteristic.read();
      }
    }
    return List<int>();
  }

  Future<void> writeServiceInt(
      String characteristicGuid, int value, bool importand) async {
    int byte1 = value & 0xff;
    int byte2 = (value >> 8) & 0xff;
    await writeService(characteristicGuid, [byte1, byte2], importand);
  }

  Future<void> writeServiceString(
      String characteristicGuid, String msg, bool importand) async {
    await writeService(characteristicGuid, utf8.encode(msg), importand);
  }

  Future<void> writeServiceBool(
      String characteristicGuid, bool value, bool importand) async {
    int byte = value ? 0x01 : 0x00;
    await writeService(characteristicGuid, [byte], importand);
  }

  Future<void> writeService(
      String characteristicGuid, List<int> data, bool importand) async {
    // print("$characteristicGuid $isWriting");
    if (!isWriting) {
      isWriting = true;
      await writeCharacteristics(characteristicGuid, data);

      if (msgStack.length > 0) {
        for (int i = 0; i < msgStack.length; i++) {
          await writeCharacteristics(msgStack[i].key, msgStack[i].value);
        }
        msgStack = List();
      }
      isWriting = false;
    } else if (importand) {
      msgStack.add(MapEntry(characteristicGuid, data));
    }
  }

  Future<void> writeCharacteristics(
      String characteristicGuid, List<int> data) async {
    if (map != null) {
      var characteristic = map[characteristicGuid];
      if (characteristic != null) {
        await characteristic.write(data);
        return;
      }
    }
  }

  void showSnackbar(IconData icon, String msg) {
    snackbar.openSnackbar(
      SnackBar(
        duration: Duration(seconds: 1),
        content: Row(
          children: <Widget>[
            Icon(icon),
            Text(msg),
          ],
        ),
      ),
      msg,
    );
  }
}
