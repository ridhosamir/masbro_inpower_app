package com.example.masbro_inpower_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Buat notification channel untuk Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
    }
    
    private fun createNotificationChannel() {
        val channelId = "masbroapp_channel"
        val channelName = "MasBro Notification"
        val channelDescription = "Channel ini digunakan untuk notifikasi penting terkait status permintaan."
        
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = channelDescription
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }
        
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
        
        // Log untuk debugging
        println("[ANDROID] Notification channel '$channelId' berhasil dibuat")
    }
}