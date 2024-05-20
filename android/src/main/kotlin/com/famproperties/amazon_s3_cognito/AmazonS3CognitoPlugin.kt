package com.famproperties.amazon_s3_cognito

import android.content.Context
import android.util.Log
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.UnsupportedEncodingException

class AmazonS3CognitoPlugin : FlutterPlugin, MethodCallHandler {

    private var awsHelper: AwsHelper? = null
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "amazon_s3_cognito")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val filePath = call.argument<String>("filePath")
        val bucket = call.argument<String>("bucket")
        val identity = call.argument<String>("identity")
        val fileName = call.argument<String>("imageName")
        val region = call.argument<String>("region")
        val subRegion = call.argument<String>("subRegion")


        if (call.method.equals("uploadImageToAmazon")) {
            val file = File(filePath)
            try {
                awsHelper = AwsHelper(context, object : AwsHelper.OnUploadCompleteListener {
                    override fun onFailed() {
                        System.out.println("\n❌ upload failed")
                        try {
                            result.success(null)
                        } catch (e: Exception) {

                        }
                    }

                    override fun onProgress(progress: Long) {
                        channel.invokeMethod("progress", progress)
                    }

                    override fun onUploadComplete(imageUrl: String) {
                        System.out.println("\n✅ upload complete: $imageUrl")
                        result.success(imageUrl)
                    }
                }, bucket!!, identity!!)
                awsHelper?.uploadImage(file)
            } catch (e: UnsupportedEncodingException) {
                e.printStackTrace()
            }
        } else if (call.method.equals("getPlatformVersion")) {
            result.success(android.os.Build.VERSION.RELEASE)
        } else {
            result.notImplemented()
        }
    }
}
