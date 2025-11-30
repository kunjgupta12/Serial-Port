package com.example.serial_port

import android.app.PendingIntent
import android.content.*
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import com.hoho.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.hoho.android.usbserial.util.SerialInputOutputManager
import cn.lalaki.SerialPort
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.charset.StandardCharsets
import java.util.concurrent.Executors

class MainActivity : FlutterActivity(), SerialInputOutputManager.Listener {

    private val METHOD_CHANNEL = "com.example.serial_port/usb"
    private val EVENT_CHANNEL = "com.example.serial_port/usb_stream"
    private val ACTION_USB_PERMISSION = "com.example.serial_port.USB_PERMISSION"
    private val TAG = "SerialPort"

    // USB
    private lateinit var usbManager: UsbManager
    private var serialPortUsb: UsbSerialPort? = null
    private var ioManager: SerialInputOutputManager? = null

    // UART / LoRa
    private var serialPortLoRa: SerialPort? = null
    private var currentLoRaDevice: String? = null

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbManager = getSystemService(USB_SERVICE) as UsbManager

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listDevices" -> {
                    val devices = listAllDevices()
                    result.success(devices)
                }

                "connectUsb" -> {
                    val deviceName = call.argument<String>("deviceName")
                    result.success(connectUsbDevice(deviceName))
                }

                "connectLoRa" -> {
                    val path = call.argument<String>("path") ?: "/dev/ttyS1"
                    val baudRate = call.argument<Int>("baudRate") ?: 9600
                    result.success(connectLoRaDevice(path, baudRate))
                }

                "disconnect" -> {
                    disconnectAll()
                    result.success("Disconnected")
                }
"autoConnectLoRa" -> {
    result.success(autoDetectLoRa())
}

                "sendData" -> {
                    val data = call.argument<String>("data")
                    result.success(sendData(data))
                }

                else -> result.notImplemented()
            }
        }

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(usbReceiver, filter)
        }

        Log.d(TAG, "✅ USB Receiver registered")
    }

    // ----------------------- Combined USB + UART -----------------------

    private fun listAllDevices(): String {
        val combined = JSONArray()

        // USB Devices
        val usbDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        for (driver in usbDrivers) {
            val device = driver.device
            val jsonObject = JSONObject()
            jsonObject.put("type", "usb")
            jsonObject.put("name", device.deviceName)
            jsonObject.put("vendorId", device.vendorId)
            jsonObject.put("productId", device.productId)
            combined.put(jsonObject)
        }

        // UART Devices (LoRa / ttyS)
        val uartFiles = File("/dev/").listFiles { _, name ->
            name.contains("ttyS", ignoreCase = true) || name.contains("ttyUSB", ignoreCase = true)
        }?.sortedBy { it.name } ?: emptyList()

        for (file in uartFiles) {
            val jsonObject = JSONObject()
            jsonObject.put("type", "uart")
            jsonObject.put("path", file.absolutePath)
            combined.put(jsonObject)
        }

        Log.d(TAG, "📡 Found devices: $combined")
        return combined.toString()
    }

    // ----------------------- USB Section -----------------------
private fun connectUsbDevice(deviceName: String?): String {
    if (deviceName == null) return "Invalid device"

    val drivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
    for (driver in drivers) {
        val device = driver.device
        if (device.deviceName == deviceName) {
            // ✅ Request permission if not already granted
            if (!usbManager.hasPermission(device)) {
                val permissionIntent = PendingIntent.getBroadcast(
                    this,
                    0,
                    Intent(ACTION_USB_PERMISSION),
                    PendingIntent.FLAG_IMMUTABLE
                )
                usbManager.requestPermission(device, permissionIntent)
                Log.d(TAG, "Requesting permission for ${device.deviceName}")
                return "Requesting USB permission..."
            }

            try {
                val connection = usbManager.openDevice(device)
                    ?: return "Cannot open USB device"

                // ✅ Explicitly claim interface (prevents controlTransfer failure)
                val usbInterface = device.getInterface(0)
                if (!connection.claimInterface(usbInterface, true)) {
                    Log.e(TAG, "Failed to claim interface for ${device.deviceName}")
                    return "Failed to claim interface"
                }

                serialPortUsb = driver.ports[0]
                serialPortUsb?.open(connection)

                // ✅ Set params after successful claim
                serialPortUsb?.setParameters(
                    9600,
                    8,
                    UsbSerialPort.STOPBITS_1,
                    UsbSerialPort.PARITY_NONE
                )

                ioManager = SerialInputOutputManager(serialPortUsb, this)
                Executors.newSingleThreadExecutor().submit(ioManager)

                Log.i(TAG, "✅ Connected successfully to ${device.deviceName}")
                return "Connected to USB: $deviceName"

            } catch (e: Exception) {
                Log.e(TAG, "❌ USB connection failed: ${e.message}")
                return "Error: ${e.message}"
            }
        }
    }
    return "USB device not found"
}

    // ----------------------- UART / LoRa Section -----------------------
private fun connectLoRaDevice(devicePath: String, baudRate: Int): String {
    return try {
        // Proper baud rate setup
        val baudValue = when (baudRate) {
            9600 -> "0000015".toInt(8)
            115200 -> "0010002".toInt(8)
            else -> "0000015".toInt(8)
        }

        // ✅ Create LoRa serial port with callback
        serialPortLoRa = SerialPort(devicePath, baudValue, object : SerialPort.DataCallback {
            override fun onData(data: ByteArray) {
                val msg = String(data, StandardCharsets.UTF_8)
                Log.d(TAG, "📩 LoRa Received: $msg")
                runOnUiThread {
                     eventSink?.success(data)
                }
            }
        })

        currentLoRaDevice = devicePath
        Log.i(TAG, "✅ LoRa connected on $devicePath @ $baudRate baud")
        "LoRa connected on $devicePath"
    } catch (e: Exception) {
        Log.e(TAG, "❌ LoRa connection failed: ${e.message}")
        "Error: ${e.message}"
    }
}
private fun autoDetectLoRa(): String {
    val devDir = File("/dev")

    val files = devDir.listFiles()
        ?.filter { it.name.startsWith("tty") } // finds ttyS*, ttyUSB*, ttysWK*
        ?: emptyList()

    if (files.isEmpty()) {
        Log.e(TAG, "❌ No /dev/tty* devices found")
        return "No serial devices found"
    }

    // Prefer ttysWK* (your LoRa device)
    val preferred = files.firstOrNull { it.name.contains("sWK", ignoreCase = true) }

    val devicePath = preferred?.absolutePath ?: files.first().absolutePath

    Log.i(TAG, "🔍 Auto-detected LoRa device: $devicePath")

    // Auto-connect using your existing method
    return connectLoRaDevice(devicePath, 9600)
}


    // ----------------------- Shared Actions -----------------------

    private fun disconnectAll() {
        try {
            ioManager?.stop()
            serialPortUsb?.close()
            serialPortUsb = null
            ioManager = null

            serialPortLoRa?.close()
            serialPortLoRa = null

            eventSink?.success("Disconnected")
            Log.i(TAG, "🔌 Disconnected all devices")
        } catch (e: Exception) {
            Log.e(TAG, "Error while disconnecting: ${e.message}")
        }
    }

    private fun sendData(data: String?): String {
        if (data == null) return "No data"

        // USB write
        serialPortUsb?.let {
            try {
                it.write(data.toByteArray(StandardCharsets.UTF_8), 1000)
                Log.d(TAG, "Sent to USB: $data")
                return "Sent to USB: $data"
            } catch (e: Exception) {
                return "Error sending USB data: ${e.message}"
            }
        }

        // UART write
        serialPortLoRa?.let {
            try {
                it.write(data.toByteArray(StandardCharsets.UTF_8))
                Log.d(TAG, "Sent to LoRa: $data")
                return "Sent to LoRa: $data"
            } catch (e: Exception) {
                return "Error sending LoRa data: ${e.message}"
            }
        }

        return "No connected serial device"
    }

    // ----------------------- USB Broadcast Receiver -----------------------

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_USB_PERMISSION) {
                synchronized(this) {
                    val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.i(TAG, "✅ USB Permission granted: ${device?.deviceName}")
                        connectUsbDevice(device?.deviceName)
                    } else {
                        Log.w(TAG, "❌ USB Permission denied for: ${device?.deviceName}")
                    }
                }
            }
        }
    }

    // ----------------------- USB Serial Callbacks -----------------------

    override fun onNewData(data: ByteArray?) {
        data?.let {
            val message = String(it, StandardCharsets.UTF_8)
            Log.d(TAG, "📩 USB Received: $message")
            runOnUiThread { eventSink?.success(message) }
        }
    }

    override fun onRunError(e: Exception?) {
        Log.e(TAG, "⚠️ Serial run error: ${e?.message}")
        runOnUiThread { eventSink?.error("ERROR", "Serial run error", e?.message) }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(usbReceiver)
            Log.d(TAG, "USB Receiver unregistered")
        } catch (e: Exception) {
            Log.w(TAG, "Receiver unregistration error: ${e.message}")
        }
    }
}
