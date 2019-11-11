import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import './bluetooth.dart';
import './bluetoothconnect.dart';
import './settings.dart';

GetIt getIt = GetIt.instance;

void main() {
  getIt.registerSingleton<ConfigNameController>(ConfigNameController("ESP32"));
  getIt.registerSingleton<SnackbarController>(SnackbarController());
  getIt.registerSingleton<BluetoothController>(BluetoothController());
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Controller',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        accentColor: Colors.blueAccent,
      ),
      home: App(),
    );
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("ESP32 Controller"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: SettingsButton(),
                  );
                },
              );
            },
          ),
          BluetoothConnect(
            deviceName: "ESP32",
          ),
        ],
      ),
      body: AppHomeScreen(),
    );
  }
}

class AppHomeScreen extends StatefulWidget {
  @override
  createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  final bluetooth = getIt.get<BluetoothController>();

  double _slider = 0.5;
  bool _pressed = false;

  void changeSlider(double value) {
    bluetooth.sendSliderValue(_slider);
    setState(() {
      _slider = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color primary = Theme.of(context).primaryColor;
    TextStyle headline = DefaultTextStyle.of(context)
        .style
        .apply(fontSizeFactor: 2.0, color: primary);

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Input",
                  textAlign: TextAlign.left,
                  style: headline,
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: "Hello World",
                  onFieldSubmitted: (String text) =>
                      bluetooth.sendTextFieldValue(text),
                ),
                SizedBox(height: 10),
                Slider(
                  value: _slider,
                  onChangeStart: changeSlider,
                  onChanged: changeSlider,
                  onChangeEnd: changeSlider,
                ),
                SizedBox(height: 10),
                RaisedButton(
                  child: Text("TOGGLE"),
                  onPressed: () {
                    setState(() {
                      _pressed = !_pressed;
                    });
                    bluetooth.sendButtonPressed(_pressed);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Divider(
            color: primary,
          ),
          SizedBox(height: 20),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Output",
                  textAlign: TextAlign.left,
                  style: headline,
                ),
                SizedBox(height: 10),
                StreamBuilder<String>(
                  initialData: "No Data arrived",
                  stream: bluetooth.getStringStream(),
                  builder: (context, snapshot) {
                    // print(snapshot.data);
                    return Text(snapshot.data);
                  },
                ),
                StreamBuilder<bool>(
                  initialData: false,
                  stream: bluetooth.getBoolStream(),
                  builder: (context, snapshot) {
                    // print(snapshot.data);
                    return Text(snapshot.data.toString());
                  },
                ),
                StreamBuilder<int>(
                  initialData: 0,
                  stream: bluetooth.getIntStream(),
                  builder: (context, snapshot) {
                    // print(snapshot.data);
                    return Text(snapshot.data.toString());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
