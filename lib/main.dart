import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serial_port/homepage.dart';

void main() {
  runApp(const SerialPortApp());
}

class SerialPortApp extends StatelessWidget {
  const SerialPortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Serial Port Tester',
      debugShowCheckedModeBanner: false,
      home: BerthingDisplayScreen(),
    );
  }
}

class SerialPortHome extends StatefulWidget {
  const SerialPortHome({super.key});

  @override
  State<SerialPortHome> createState() => _SerialPortHomeState();
}

class _SerialPortHomeState extends State<SerialPortHome> {
  static const _methodChannel = MethodChannel('com.example.serial_port/usb');
  static const _eventChannel = EventChannel(
    'com.example.serial_port/usb_stream',
  );

  List<dynamic> _devices = [];
  String?
  _connectedDevice; // stores a display id like 'usb:/dev/bus/usb/...' or 'uart:/dev/ttyS1'
  String _status = 'Idle';
  bool _isScanning = false;
  bool _isConnecting = false;

  final TextEditingController _sendController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _log = [];
  StreamSubscription? _usbSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSerialData();
  }

  /// Listen to EventChannel from Android native (USB/UART incoming data)
  void _listenToSerialData() {
    _usbSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        setState(() {
          _log.add("${_timestamp()} RX → $event");
        });
        _autoScroll();
      },
      onError: (error) {
        setState(() {
          _log.add("${_timestamp()} ⚠️ Error: $error");
        });
        _autoScroll();
      },
    );
  }

  String _timestamp() {
    final now = DateTime.now();
    return "[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}]";
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Scans for devices by calling Kotlin `listDevices`
  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });
    try {
      final String result = await _methodChannel.invokeMethod('listDevices');
      final devices = jsonDecode(result);
      setState(() {
        _devices = devices;
        _status = devices.isEmpty
            ? 'No devices found'
            : 'Devices found (${devices.length})';
      });
      _log.add("${_timestamp()} 🔍 Found devices: $devices");
    } catch (e) {
      setState(() => _status = 'Scan failed: $e');
      _log.add("${_timestamp()} ❌ Scan failed: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Connects to a device. Decides between USB and UART based on device type.
  Future<void> _connectDevice(Map<String, dynamic> device) async {
    setState(() {
      _isConnecting = true;
      _status = "Connecting...";
    });

    try {
      String result = "Unknown";
      String displayId;

      if (device['type'] == 'usb') {
        final deviceName = device['name'] as String?;
        if (deviceName == null) throw Exception('Invalid USB device name');
        result = await _methodChannel.invokeMethod('connectUsb', {
          'deviceName': deviceName,
        });
        displayId = 'usb:$deviceName';
      } else if (device['type'] == 'uart') {
        final path = device['path'] as String?;
        if (path == null) throw Exception('Invalid UART path');
        // default baudRate 9600, change if you wish to show UI for baud selection
        result = await _methodChannel.invokeMethod('connectLoRa', {
          'path': path,
          'baudRate': 9600,
        });
        displayId = 'uart:$path';
      } else {
        throw Exception('Unknown device type');
      }

      setState(() {
        _connectedDevice = displayId;
        _status = result.toString();
      });
      _log.add("${_timestamp()} ✅ $result");
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
      _log.add("${_timestamp()} ❌ Connection failed: $e");
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  /// Disconnects from device (calls native `disconnect`)
  Future<void> _disconnectDevice() async {
    try {
      final result = await _methodChannel.invokeMethod('disconnect');
      setState(() {
        _connectedDevice = null;
        _status = result.toString();
      });
      _log.add("${_timestamp()} 🔌 $result");
    } catch (e) {
      _log.add("${_timestamp()} ❌ Disconnect failed: $e");
    }
  }

  /// Sends text data to device (calls native `sendData`)
  Future<void> _sendData() async {
    final text = _sendController.text.trim();
    if (text.isEmpty) return;
    try {
      final result = await _methodChannel.invokeMethod('sendData', {
        'data': text,
      });
      _log.add("${_timestamp()} TX → $text");
      _log.add("${_timestamp()} ✅ $result");
      _sendController.clear();
    } catch (e) {
      _log.add("${_timestamp()} ❌ Send failed: $e");
    }
    _autoScroll();
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectedDevice != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Port Tester (E32)'),
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          if (isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.usb_rounded,
                color: Colors.greenAccent.shade400,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scan + Status Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanDevices,
                  icon: const Icon(Icons.refresh),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan Devices'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Device List
          if (_devices.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final d = Map<String, dynamic>.from(_devices[index] as Map);
                  final isThisConnected =
                      _connectedDevice != null &&
                      (_connectedDevice == 'usb:${d['name']}' ||
                          _connectedDevice == 'uart:${d['path']}');

                  final title = d['type'] == 'usb'
                      ? (d['name'] ?? 'USB device')
                      : (d['path'] ?? 'UART device');
                  final subtitle = d['type'] == 'usb'
                      ? "VID: ${d['vendorId'] ?? '-'} | PID: ${d['productId'] ?? '-'}"
                      : "UART: ${d['path'] ?? '-'}";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        d['type'] == 'usb' ? Icons.usb_rounded : Icons.router,
                        color: isThisConnected ? Colors.green : Colors.grey,
                      ),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      trailing: ElevatedButton(
                        onPressed: _isConnecting
                            ? null
                            : isThisConnected
                            ? null
                            : () => _connectDevice(d),
                        child: Text(isThisConnected ? 'Connected' : 'Connect'),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Send + Disconnect
          if (isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sendController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter command (e.g. AT)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _sendData,
                    child: const Text('Send'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: _disconnectDevice,
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Log Output
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      _log[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
