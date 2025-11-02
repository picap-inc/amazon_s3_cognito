import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AmazonS3Cognito {
  static const MethodChannel _channel =
      const MethodChannel('amazon_s3_cognito');

  // Solo loggear en modo debug
  static bool enableDebugLogs = kDebugMode;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String?> upload(String filepath, String bucket, String identity,
      [Function(double)? onProgress]) async {
    if (enableDebugLogs) {
      print('[AmazonS3Cognito] 🚀 Iniciando upload...');
      print('[AmazonS3Cognito] 📁 FilePath: ${_sanitizePath(filepath)}');
      print('[AmazonS3Cognito] 🗄️  Bucket: ${_sanitizeBucket(bucket)}');
      print('[AmazonS3Cognito] 🆔 Identity Pool: ${_sanitizeIdentity(identity)}');
    }

    // Verificar si el archivo existe desde Dart
    final file = File(filepath);
    if (!await file.exists()) {
      print('[AmazonS3Cognito] ❌ ERROR CRÍTICO: El archivo NO EXISTE en Dart');
      throw Exception('El archivo no existe: $filepath');
    }

    final fileSize = await file.length();
    if (enableDebugLogs) {
      print('[AmazonS3Cognito] ✅ Archivo verificado en Dart: $fileSize bytes');
    }

    final Map<String, dynamic> params = {
      'filePath': filepath,
      'bucket': bucket,
      'identity': identity
    };

    _channel.setMethodCallHandler((handler) async {
      switch (handler.method) {
        case 'progress':
          final progress = handler.arguments.toDouble();
          if (enableDebugLogs) {
            print('[AmazonS3Cognito] 📊 Progress: ${progress.toStringAsFixed(2)}%');
          }
          onProgress?.call(progress);
          break;
        case 'nativeLog':
          // Recibir logs desde el código nativo (solo en debug)
          if (enableDebugLogs) {
            print('[NATIVE] ${handler.arguments}');
          }
          break;
        default:
          if (enableDebugLogs) {
            print('[AmazonS3Cognito] ⚠️  Método desconocido recibido: ${handler.method}');
          }
          break;
      }
    });

    try {
      if (enableDebugLogs) {
        print('[AmazonS3Cognito] 📤 Invocando método nativo uploadImageToAmazon...');
        print('[AmazonS3Cognito] 📦 Parámetros: ${_sanitizeParams(params)}');
      }

      final String? imagePath =
          await _channel.invokeMethod('uploadImageToAmazon', params);

      if (imagePath != null) {
        if (enableDebugLogs) {
          print('[AmazonS3Cognito] ✅ Upload exitoso!');
        }
      } else {
        // Siempre loggear errores críticos
        print('[AmazonS3Cognito] ❌ Upload falló');
        if (enableDebugLogs) {
          print('[AmazonS3Cognito] ❌ Se recibió null del método nativo');
        }
      }

      return imagePath;
    } on PlatformException catch (e) {
      // Siempre loggear errores críticos pero sin info sensible
      print('[AmazonS3Cognito] ❌ Error en upload: ${e.code}');
      if (enableDebugLogs) {
        print('[AmazonS3Cognito] ❌ Mensaje: ${e.message}');
        print('[AmazonS3Cognito] ❌ Detalles: ${e.details}');
        print('[AmazonS3Cognito] 📍 StackTrace: ${e.stacktrace}');
      }
      rethrow;
    } catch (e, stackTrace) {
      print('[AmazonS3Cognito] ❌ Error en upload: ${e.runtimeType}');
      if (enableDebugLogs) {
        print('[AmazonS3Cognito] ❌ Detalle: $e');
        print('[AmazonS3Cognito] 📍 StackTrace: $stackTrace');
      }
      rethrow;
    }
  }

  // Funciones para sanitizar información sensible
  static String _sanitizePath(String path) {
    // Solo mostrar el nombre del archivo, no la ruta completa
    return path.split('/').last;
  }

  static String _sanitizeBucket(String bucket) {
    // Ocultar parte del bucket en producción
    if (enableDebugLogs) return bucket;
    return bucket.length > 4 ? '${bucket.substring(0, 2)}***' : '***';
  }

  static String _sanitizeIdentity(String identity) {
    // Mostrar solo la región en producción
    if (enableDebugLogs) return identity;
    return identity.split(':').first + ':***';
  }

  static Map<String, dynamic> _sanitizeParams(Map<String, dynamic> params) {
    return {
      'filePath': _sanitizePath(params['filePath']),
      'bucket': _sanitizeBucket(params['bucket']),
      'identity': _sanitizeIdentity(params['identity']),
    };
  }

  static Future<String> delete(String bucket, String identity, String imageName,
      String region, String subRegion) async {
    final Map<String, dynamic> params = {
      'bucket': bucket,
      'identity': identity,
      'imageName': imageName,
      'region': region,
      'subRegion': subRegion
    };
    final String imagePath = await _channel.invokeMethod('deleteImage', params);
    return imagePath;
  }
}
