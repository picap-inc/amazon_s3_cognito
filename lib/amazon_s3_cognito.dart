import 'dart:async';

import 'package:flutter/services.dart';

class AmazonS3Cognito {
  static const MethodChannel _channel = const MethodChannel('amazon_s3_cognito');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> upload(String filepath, String bucket, String identity, [Function(double) onProgress = null]) async {
    final Map<String, dynamic> params = <String, dynamic>{'filePath': filepath, 'bucket': bucket, 'identity': identity};
    _channel.setMethodCallHandler((handler) {
      switch (handler.method) {
        case "progress" :
          if(onProgress != null)
            onProgress(handler.arguments);
          break;
        default:
      }
    });
    final String imagePath = await _channel.invokeMethod('uploadImageToAmazon', params);

    return imagePath;
  }

  static Future<String> delete(String bucket, String identity, String imageName, String region, String subRegion) async {
    final Map<String, dynamic> params = <String, dynamic>{'bucket': bucket, 'identity': identity, 'imageName': imageName, 'region': region, 'subRegion': subRegion};
    final String imagePath = await _channel.invokeMethod('deleteImage', params);
    return imagePath;
  }
}
