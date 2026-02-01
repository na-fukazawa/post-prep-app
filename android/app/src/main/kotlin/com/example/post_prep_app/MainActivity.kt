package com.example.post_prep_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
  private val channelName = "post_prep_app/x_share"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "shareToX" -> {
            val text = call.argument<String>("text") ?: ""
            val imagePaths = call.argument<List<String>>("imagePaths") ?: emptyList()
            result.success(shareToX(text, imagePaths))
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun shareToX(text: String, imagePaths: List<String>): Boolean {
    val imageUris = ArrayList<Uri>()
    for (path in imagePaths) {
      val file = File(path)
      if (!file.exists()) continue
      val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
      imageUris.add(uri)
    }

    val intent = if (imageUris.isNotEmpty()) {
      if (imageUris.size == 1) {
        Intent(Intent.ACTION_SEND).apply {
          type = "image/*"
          putExtra(Intent.EXTRA_STREAM, imageUris[0])
        }
      } else {
        Intent(Intent.ACTION_SEND_MULTIPLE).apply {
          type = "image/*"
          putParcelableArrayListExtra(Intent.EXTRA_STREAM, imageUris)
        }
      }
    } else {
      Intent(Intent.ACTION_SEND).apply { type = "text/plain" }
    }

    if (text.isNotEmpty()) {
      intent.putExtra(Intent.EXTRA_TEXT, text)
    }
    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    intent.`package` = "com.twitter.android"

    return try {
      startActivity(intent)
      true
    } catch (e: Exception) {
      false
    }
  }
}
