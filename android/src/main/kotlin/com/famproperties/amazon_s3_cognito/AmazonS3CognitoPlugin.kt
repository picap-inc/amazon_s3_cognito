package com.famproperties.amazon_s3_cognito

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.jetbrains.annotations.NotNull
import java.io.File
import java.io.UnsupportedEncodingException

class AmazonS3CognitoPlugin  private constructor(private val context: Context,private val channel: MethodChannel) : MethodCallHandler {
    private var awsHelper: AwsHelper? = null

    //var channel: MethodChannel? = null

    companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {

      val channel = MethodChannel(registrar.messenger(), "amazon_s3_cognito")
        val instance = AmazonS3CognitoPlugin(registrar.context(), channel)
        channel.setMethodCallHandler(instance)
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
      val filePath = call.argument<String>("filePath")
      val bucket = call.argument<String>("bucket")
      val identity = call.argument<String>("identity")
      val fileName = call.argument<String>("imageName")
      val region = call.argument<String>("region")
      val subRegion = call.argument<String>("subRegion")


      if (call.method.equals("uploadImageToAmazon")) {
          val file = File(filePath)
          try {
              awsHelper = AwsHelper(context, object : AwsHelper.OnUploadCompleteListener{
                  override fun onFailed() {

                      System.out.println("\n❌ upload failed")
                      try{
                          result.success(null)
                      }catch (e:Exception){

                      }
                  }

                  override fun onProgress(progress: Long) {
                      channel.invokeMethod("progress", progress)
                  }

                  override fun onUploadComplete(@NotNull imageUrl: String) {
                      System.out.println("\n✅ upload complete: $imageUrl")
                      result.success(imageUrl)
                  }
              },  bucket!!, identity!!)
              awsHelper!!.uploadImage(file)
          } catch (e: UnsupportedEncodingException) {
              e.printStackTrace()
          }

      } else if (call.method.equals("uploadImage")) {


      } else if (call.method.equals("downloadImage")) {


      } else if (call.method.equals("deleteImage")) {

      } else {
          result.notImplemented()
      }
  }
}
