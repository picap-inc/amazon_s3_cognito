# Amazon S3 Cognito

Amazon S3 Plugin for Flutter

Unofficial Amazon S3 plugin written in Dart for Flutter.

This plugin comes from the repository [AmazonS3Cognito](https://github.com/prachiFam/amazon_s3_cognito) by PrachiFam

## Index
* [Usage](#usage)
    * [Demo](#demo)
* [Installation](#installation)
    * [Android](#nativeAndroid)
    * [iOS](#nativeiOS)
* [Collaborators](#contributors)


<a name="usage"></a>
## Usage
To use this plugin, add `amazon_s3_cognito` as a dependency in your pubspec.yaml file

```yaml
dependencies:
	amazon_s3_cognito:
  		git:
    		url: git@github.com:picap-inc/amazon_s3_cognito.git
      		ref: main
```
<a name="demo"></a>
### Demo


``` dart
import 'package:amazon_s3_cognito/amazon_s3_cognito.dart';
import 'package:amazon_s3_cognito/aws_region.dart';

String uploadedImageUrl = await AmazonS3Cognito.uploadImage(
          _image.path, BUCKET_NAME, IDENTITY_POOL_ID);


// Use the following code to specify the region and subregion to upload images
String uploadedImageUrl = await AmazonS3Cognito.upload(
            _image.path,
            BUCKET_NAME,
            IDENTITY_POOL_ID,
            IMAGE_NAME,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)                                            

```

<a name="installation"></a>
## Installation

<a name="nativeAndroid"></a>
### Android

Added [awsconfiguration.json](https://github.com/picap-inc/amazon_s3_cognito/blob/main/example/android/app/src/main/res/raw/awsconfiguration.json) to your android project in a raw folder in res

<a name="nativeiOS"></a>
### iOS

No configuration required - the plugin should work out of the box.

<a name="contributors"></a>
## Collaborators

| Developers  |  |
| ------------- | ------------- |
| Daniel Rodriguez  | <a href="https://github.com/dabeto"><img src="https://avatars.githubusercontent.com/u/2546455?v=4" width="50" height="50" /></a>  |
| Juan Labrador  | <a href="https://github.com/juanlabrador"><img src="https://avatars.githubusercontent.com/u/6761048" width="50" height="50" /></a>  |
| Martin Escobar  | <a href="https://github.com/martinale14"><img src="https://avatars.githubusercontent.com/u/56127727?v=4" width="50" height="50" /></a>  |
