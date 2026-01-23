package com.famproperties.amazon_s3_cognito

import android.content.Context
import android.util.Log
import com.amazonaws.auth.CognitoCachingCredentialsProvider
import com.amazonaws.mobile.config.AWSConfiguration
import com.amazonaws.mobileconnectors.s3.transferutility.TransferListener
import com.amazonaws.mobileconnectors.s3.transferutility.TransferState
import com.amazonaws.mobileconnectors.s3.transferutility.TransferUtility
import com.amazonaws.regions.Regions
import com.amazonaws.services.s3.AmazonS3Client
import java.io.File
import java.io.UnsupportedEncodingException
import java.util.*

class AwsHelper(
    private val context: Context,
    private val onUploadCompleteListener: OnUploadCompleteListener,
    private val BUCKET_PATH: String,
    private val IDENTITY_POOL_ID: String
) {

    private var transferUtility: TransferUtility
    private var nameOfUploadedFile: String? = null

    // Separar bucket real del folder path
    private val actualBucket: String
    private val folderPath: String?

    init {
        // El BUCKET_PATH puede venir como "bucket/folder" o solo "bucket"
        val parts = BUCKET_PATH.split("/", limit = 2)
        actualBucket = parts[0]
        folderPath = if (parts.size > 1) parts[1] else null

        Log.d(TAG, "🔧 Inicializando AwsHelper...")
        Log.d(TAG, "🗄️  Bucket recibido: $BUCKET_PATH")
        Log.d(TAG, "🗄️  Bucket real: $actualBucket")
        Log.d(TAG, "📂 Folder path: $folderPath")
        Log.d(TAG, "🆔 Identity Pool ID: $IDENTITY_POOL_ID")

        try {
            Log.d(TAG, "📋 Creando AWSConfiguration...")
            val awsConfiguration = AWSConfiguration(context)

            // Auto-detectar la región desde el Identity Pool ID
            val identityRegion = IDENTITY_POOL_ID.split(":").firstOrNull() ?: "us-east-1"
            Log.d(TAG, "🌎 Región extraída del Identity Pool: $identityRegion")

            val cognitoRegion = when (identityRegion) {
                "us-east-1" -> {
                    Log.d(TAG, "🌎 Región AUTO-DETECTADA: US_EAST_1")
                    Regions.US_EAST_1
                }
                "us-east-2" -> {
                    Log.d(TAG, "🌎 Región AUTO-DETECTADA: US_EAST_2")
                    Regions.US_EAST_2
                }
                "us-west-1" -> {
                    Log.d(TAG, "🌎 Región AUTO-DETECTADA: US_WEST_1")
                    Regions.US_WEST_1
                }
                "us-west-2" -> {
                    Log.d(TAG, "🌎 Región AUTO-DETECTADA: US_WEST_2")
                    Regions.US_WEST_2
                }
                "eu-west-1" -> {
                    Log.d(TAG, "🌎 Región AUTO-DETECTADA: EU_WEST_1")
                    Regions.EU_WEST_1
                }
                else -> {
                    Log.w(TAG, "⚠️  Región no reconocida: $identityRegion, usando US_EAST_1 por defecto")
                    Regions.US_EAST_1
                }
            }

            Log.d(TAG, "🔑 Creando CognitoCachingCredentialsProvider con región: $cognitoRegion")
            val awsCreds = CognitoCachingCredentialsProvider(context, IDENTITY_POOL_ID, cognitoRegion)

            Log.d(TAG, "☁️  Creando AmazonS3Client...")
            val s3Client = AmazonS3Client(awsCreds)

            Log.d(TAG, "🚀 Construyendo TransferUtility...")
            transferUtility = TransferUtility.builder()
                .context(context)
                .awsConfiguration(awsConfiguration)
                .s3Client(s3Client)
                .build()

            Log.i(TAG, "✅ AwsHelper inicializado exitosamente!")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error al inicializar AwsHelper: ${e.message}")
            e.printStackTrace()
            throw e
        }
    }

    private val uploadedUrl: String
        get() = getUploadedUrl(nameOfUploadedFile)

    private fun getUploadedUrl(fileName: String?): String {
        // Extraer la región del Identity Pool ID (formato: "region:pool-id")
        val region = IDENTITY_POOL_ID.split(":").firstOrNull() ?: "us-east-1"
        // Construir el key completo: folder/filename o solo filename
        val fullKey = if (folderPath != null) "$folderPath/$fileName" else fileName
        return "https://$actualBucket.s3.$region.amazonaws.com/$fullKey"
    }

    @Throws(UnsupportedEncodingException::class)
    fun uploadImage(image: File): String {
        Log.d(TAG, "📤 Iniciando uploadImage()...")
        Log.d(TAG, "📁 Nombre del archivo: ${image.name}")
        Log.d(TAG, "📏 Tamaño del archivo: ${image.length()} bytes")
        Log.d(TAG, "📂 Ruta completa: ${image.absolutePath}")

        //nameOfUploadedFile = clean(image.name)
        nameOfUploadedFile = image.name

        // Construir el key completo: folder/filename o solo filename
        val fullKey = if (folderPath != null) "$folderPath/$nameOfUploadedFile" else nameOfUploadedFile

        Log.d(TAG, "🏷️  Nombre del archivo a subir: $nameOfUploadedFile")
        Log.d(TAG, "🔑 Key completo: $fullKey")

        try {
            Log.d(TAG, "🚀 Llamando transferUtility.upload()...")
            Log.d(TAG, "   - Bucket: $actualBucket")
            Log.d(TAG, "   - Key: $fullKey")
            val transferObserver = transferUtility.upload(actualBucket, fullKey, image)
            Log.d(TAG, "✅ TransferObserver creado con ID: ${transferObserver.id}")

            transferObserver.setTransferListener(object : TransferListener {
                override fun onStateChanged(id: Int, state: TransferState) {
                    Log.d(TAG, "🔄 Estado cambiado para transfer ID [$id]: $state")

                    if (state == TransferState.COMPLETED) {
                        val uploadedUrl = getUploadedUrl(nameOfUploadedFile)
                        Log.i(TAG, "✅ UPLOAD COMPLETADO!")
                        Log.i(TAG, "🔗 URL generada: $uploadedUrl")
                        onUploadCompleteListener.onUploadComplete(uploadedUrl)
                    }

                    if (state == TransferState.FAILED) {
                        Log.e(TAG, "❌ UPLOAD FALLÓ - Estado: FAILED")
                        onUploadCompleteListener.onFailed()
                    }

                    if (state == TransferState.CANCELED) {
                        Log.w(TAG, "⚠️  Upload cancelado")
                    }

                    if (state == TransferState.IN_PROGRESS) {
                        Log.d(TAG, "⏳ Upload en progreso...")
                    }

                    if (state == TransferState.WAITING || state == TransferState.WAITING_FOR_NETWORK) {
                        Log.d(TAG, "⏸️  Upload esperando (red o recursos)...")
                    }

                    if (state == TransferState.PAUSED) {
                        Log.w(TAG, "⏸️  Upload pausado")
                    }
                }

                override fun onProgressChanged(id: Int, bytesCurrent: Long, bytesTotal: Long) {
                    val progress = (100 * bytesCurrent / bytesTotal)
                    Log.d(TAG, "📊 Progreso ID [$id]: $progress% ($bytesCurrent/$bytesTotal bytes)")
                    onUploadCompleteListener.onProgress(progress)
                }

                override fun onError(id: Int, ex: Exception) {
                    Log.e(TAG, "❌ ERROR en upload ID [$id]!")
                    Log.e(TAG, "❌ Mensaje de error: ${ex.message}")
                    Log.e(TAG, "❌ Tipo de excepción: ${ex.javaClass.simpleName}")
                    ex.printStackTrace()
                }
            })

            Log.d(TAG, "🔗 URL esperada al completar: $uploadedUrl")
            return uploadedUrl
        } catch (e: Exception) {
            Log.e(TAG, "❌ Excepción al iniciar upload: ${e.message}")
            e.printStackTrace()
            throw e
        }
    }

    @Throws(UnsupportedEncodingException::class)
    fun clean(filePath: String): String {
        return filePath.replace("[^A-Za-z0-9 ]".toRegex(), "")
    }

    interface OnUploadCompleteListener {
        fun onUploadComplete(imageUrl: String)
        fun onFailed()
        fun onProgress(progress: Long)
    }

    companion object {
        private val TAG = AwsHelper::class.java.simpleName
    }
}
