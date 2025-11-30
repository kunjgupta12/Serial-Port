import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serial_port/widget/supprt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerthingDisplayScreen extends StatefulWidget {
  const BerthingDisplayScreen({super.key});

  @override
  State<BerthingDisplayScreen> createState() => _BerthingDisplayScreenState();
}

class _BerthingDisplayScreenState extends State<BerthingDisplayScreen> {
  static const _methodChannel = MethodChannel('com.example.serial_port/usb');
  static const _eventChannel = EventChannel(
    'com.example.serial_port/usb_stream',
  );
  int sensor1Speed = 0;
  int sensor1Distance = 0;
  int sensor2Speed = 0;
  int sensor2Distance = 0;
  int angleDegree = 0;

  List<dynamic> _devices = [];
  String?
  _connectedDevice; // stores a display id like 'usb:/dev/bus/usb/...' or 'uart:/dev/ttyS1'
  String _status = 'Idle';
  bool _isScanning = false;
  bool _isConnecting = false;
  final List<String> _log = [];
  StreamSubscription? _usbSubscription;
  String terminalName = "Terminal Name";
  final TextEditingController _terminalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenToSerialData();
    loadTerminalName();
  }

  Future<void> loadTerminalName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      terminalName = prefs.getString('terminal_name') ?? "Terminal Name";
    });
  }

  /// Convert hex string like "007800f00032012c0046" → integer list
  List<int> decodeHexToValues(String hex) {
    final bytes = <int>[];

    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }

    final out = <int>[];

    for (int i = 0; i < bytes.length; i += 2) {
      out.add((bytes[i] << 8) | bytes[i + 1]);
    }

    return out;
  }

  String cleanHex(String input) {
    final hexReg = RegExp(r'[0-9a-fA-F]');
    return input.split('').where((c) => hexReg.hasMatch(c)).join();
  }

  String? extractHexPacket(String text) {
    final reg = RegExp(r'([0-9a-fA-F]{20})');
    final match = reg.firstMatch(text);
    return match?.group(0);
  }

  void _listenToSerialData() {
    _usbSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        // Accept ONLY raw bytes
        if (event is Uint8List) {
          final bytes = event;

          // Expect EXACTLY 10 bytes (your packet size)
          if (bytes.length != 10) {
            _log.add("${_timestamp()} ⚠️ Wrong byte size: ${bytes.length}");
            return;
          }

          // Convert bytes to HEX
          final hex = bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();

          _log.add("${_timestamp()} RX(bytes) → $hex");

          _processHexPacket(hex);
          return;
        }

        // Ignore any non-bytes (this is platform text noise)
        _log.add("${_timestamp()} ⚠️ Ignored non-byte event");
      },
      onError: (error) {
        _log.add("${_timestamp()} ⚠️ Error: $error");
      },
    );
  }

  void _processHexPacket(String hex) {
    //if (hex.length != 20) return; // 10 bytes

    final values = decodeHexToValues(hex);

    if (values.length == 5) {
      setState(() {
        angleDegree = values[0];
        sensor1Speed = values[1];
        sensor1Distance = values[2];
        sensor2Speed = values[3];
        sensor2Distance = values[4];
      });
    }
  }

  Future<void> connectLoRaWK2() async {
    setState(() {
      _isConnecting = true;
      _status = "Connecting to /dev/ttysWK2...";
    });

    try {
      const devicePath = "/dev/ttysWK2";

      final result = await _methodChannel.invokeMethod("connectLoRa", {
        "path": devicePath,
        "baudRate": 9600,
      });

      setState(() {
        _connectedDevice = devicePath;
        _status = "Connected to $devicePath";
      });

      _log.add("${_timestamp()} ✅ Connected to $devicePath");
    } catch (e) {
      setState(() {
        _status = "Connection failed: $e";
      });
      _log.add("${_timestamp()} ❌ Failed to connect: $e");
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _openSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _terminalController.text = terminalName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: TextField(
            controller: _terminalController,
            decoration: const InputDecoration(
              labelText: "Enter Terminal Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = _terminalController.text.trim();
                if (newName.isNotEmpty) {
                  await prefs.setString('terminal_name', newName);
                  setState(() {
                    terminalName = newName;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> disconnectLoRa() async {
    try {
      await _methodChannel.invokeMethod("disconnect");

      setState(() {
        _connectedDevice = null;
        _status = "Disconnected";
      });

      _log.add("${_timestamp()} 🔌 Disconnected");
    } catch (e) {
      _log.add("${_timestamp()} ⚠️ Disconnect error: $e");
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return "[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}]";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Water.png'),
              fit: BoxFit.fill,
            ),
          ),
          // width: w * 0.99, // Match tablet width
          height: h * 0.99,
          padding: const EdgeInsets.all(5),

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: w * 0.3,
                    padding: EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/client_logo.jpeg',
                      height: h * 0.17,
                      width: w * 0.2,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Text(
                    textAlign: TextAlign.center,
                    "Hi-TECH \nBIRTH APPROACH\n SYSTEM",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: w * 0.3,
                    padding: EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset('assets/logo.jpeg', height: h * 0.17),
                  ),
                ],
              ),
              SizedBox(height: h * 0.02),
              // TOP HEADER: Terminal Name + Logo
              SizedBox(
                height: h * 0.18,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          terminalName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Expanded(
                    //   flex: 1,
                    //   child: Container(
                    //     color: Colors.black,
                    //     child: ListView.builder(
                    //       controller: _scrollController,
                    //       itemCount: _log.length,
                    //       itemBuilder: (context, index) {
                    //         return Padding(
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 8,
                    //             vertical: 2,
                    //           ),
                    //           child: Text(
                    //             _log[index],
                    //             style: const TextStyle(
                    //               color: Colors.greenAccent,
                    //               fontSize: 13,
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //   ),
                    // ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 12, right: 10),
                        child: dataBox(
                          width: w * 0.4,
                          title: "Angle(Degree)",
                          value: "$angleDegree°",
                          height: h * 0.2,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 8, right: 10),
                        child: compassBox(height: h * 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: h * 0.02),

              // MAIN GRID
              Center(
                child: SizedBox(
                  width: w * 0.95, // Controls total width of sensor section
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sensorTile(
                        label: "Sensor",
                        number: "1",
                        height: h * 0.40,
                      ),
                      SizedBox(width: w * 0.03),
                      // LEFT COLUMN : SENSOR 1
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            dataBox(
                              width: w * 0.4,
                              title: "Speed (cm/s)",
                              value: sensor1Speed.toString(),

                              height: h * 0.2,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              width: w * 0.4,
                              title: "Distance  (m)",
                              value: sensor1Distance.toString(),

                              height: h * 0.2,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: w * 0.03),

                      // RIGHT COLUMN : SENSOR 2
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            dataBox(
                              width: w * 0.4,
                              title: "Speed (cm/s)",
                              value: sensor2Speed.toString(),

                              height: h * 0.2,
                            ),
                            SizedBox(height: h * 0.02),
                            dataBox(
                              width: w * 0.4,
                              title: "Distance  (m)",
                              value: sensor2Distance.toString(),

                              height: h * 0.2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      sensorTile(
                        label: "Sensor",
                        number: "2",
                        height: h * 0.40,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "www.hitechelastomers.com",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (_connectedDevice == null) {
                        connectLoRaWK2(); // CONNECT
                      } else {
                        disconnectLoRa(); // DISCONNECT
                      }
                    },
                    child: Text(
                      _connectedDevice == null ? "Connect" : "Disconnect",
                      style: const TextStyle(color: Colors.black, fontSize: 25),
                    ),
                  ),
                  IconButton(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
