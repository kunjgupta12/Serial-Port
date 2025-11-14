package com.example.serial_port

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbManager
import android.widget.Toast

class UsbPermissionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        if (intent.action == "com.example.serial_port.USB_PERMISSION") {
            val device = intent.getParcelableExtra<android.hardware.usb.UsbDevice>(UsbManager.EXTRA_DEVICE)
            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)

            if (granted) {
                Toast.makeText(context, "Permission granted for ${device?.deviceName}", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(context, "Permission denied for ${device?.deviceName}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
