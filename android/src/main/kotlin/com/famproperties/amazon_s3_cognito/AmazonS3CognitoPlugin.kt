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

        Log.d("AmazonS3Plugin", "🔵 Método llamado: ${call.method}")
        Log.d("AmazonS3Plugin", "📁 FilePath recibido: $filePath")
        Log.d("AmazonS3Plugin", "🗄️  Bucket recibido: $bucket")
        Log.d("AmazonS3Plugin", "🆔 Identity Pool recibido: $identity")

        if (call.method.equals("uploadImageToAmazon")) {
            if (filePath == null || bucket == null || identity == null) {
                Log.e("AmazonS3Plugin", "❌ Parámetros faltantes!")
                Log.e("AmazonS3Plugin", "FilePath es null: ${filePath == null}")
                Log.e("AmazonS3Plugin", "Bucket es null: ${bucket == null}")
                Log.e("AmazonS3Plugin", "Identity es null: ${identity == null}")
                result.error("MISSING_PARAMS", "Faltan parámetros requeridos", null)
                return
            }

            val file = File(filePath)
            Log.d("AmazonS3Plugin", "📂 Verificando archivo...")
            Log.d("AmazonS3Plugin", "Archivo existe: ${file.exists()}")
            Log.d("AmazonS3Plugin", "Archivo es legible: ${file.canRead()}")
            Log.d("AmazonS3Plugin", "Tamaño del archivo: ${file.length()} bytes")

            if (!file.exists()) {
                Log.e("AmazonS3Plugin", "❌ El archivo no existe: $filePath")
                result.error("FILE_NOT_FOUND", "El archivo no existe", null)
                return
            }

            try {
                Log.d("AmazonS3Plugin", "🔧 Inicializando AwsHelper...")
                awsHelper = AwsHelper(context, object : AwsHelper.OnUploadCompleteListener {
                    override fun onFailed() {
                        Log.e("AmazonS3Plugin", "❌ Upload FALLÓ en callback onFailed()")
                        try {
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e("AmazonS3Plugin", "❌ Error al enviar resultado de fallo: ${e.message}")
                        }
                    }

                    override fun onProgress(progress: Long) {
                        Log.d("AmazonS3Plugin", "📊 Progreso: $progress%")
                        channel.invokeMethod("progress", progress)
                    }

                    override fun onUploadComplete(imageUrl: String) {
                        Log.i("AmazonS3Plugin", "✅ Upload COMPLETADO exitosamente!")
                        Log.i("AmazonS3Plugin", "🔗 URL resultante: $imageUrl")
                        result.success(imageUrl)
                    }
                }, bucket!!, identity!!)

                Log.d("AmazonS3Plugin", "🚀 Iniciando upload del archivo...")
                awsHelper?.uploadImage(file)
                Log.d("AmazonS3Plugin", "📤 Método uploadImage() llamado exitosamente")
            } catch (e: UnsupportedEncodingException) {
                Log.e("AmazonS3Plugin", "❌ UnsupportedEncodingException: ${e.message}")
                e.printStackTrace()
                result.error("ENCODING_ERROR", e.message, null)
            } catch (e: Exception) {
                Log.e("AmazonS3Plugin", "❌ Excepción general: ${e.message}")
                e.printStackTrace()
                result.error("UPLOAD_ERROR", e.message, null)
            }
        } else if (call.method.equals("getPlatformVersion")) {
            result.success(android.os.Build.VERSION.RELEASE)
        } else {
            result.notImplemented()
        }
    }
}
