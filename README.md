# amazon_s3_cognito


Amazon S3 plugin for Flutter

Unofficial Amazon S3 plugin written in Dart for Flutter.

The plugin is extension if flutter-amazon-s3 plugin which can be found here
https://pub.dev/packages/flutter_amazon_s3. I changed the deprecated methods on ios and android to make it work. 

Plugin in maintained by fäm properties<no-reply@famproperties.com>.

## Usage
To use this plugin, add `amazon_s3_cognito` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).


```yaml
dependencies:
The package is android-x compatible
amazon_s3_cognito:
  git:
    url: git://github.com/dabeto/amazon_s3_cognito.git
```

### Example



``` dart
import 'package:amazon_s3_cognito/amazon_s3_cognito.dart';
import 'package:amazon_s3_cognito/aws_region.dart';

String uploadedImageUrl = await AmazonS3Cognito.uploadImage(
          _image.path, BUCKET_NAME, IDENTITY_POOL_ID);


//Use the below code to specify the region and sub region for image upload
String uploadedImageUrl = await AmazonS3Cognito.upload(
            _image.path,
            BUCKET_NAME,
            IDENTITY_POOL_ID,
            IMAGE_NAME,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)                                            

```

## Installation


### Android

add awsconfiguration.json and AndroidManifest.xml as in this doc:
https://github.com/awsdocs/aws-mobile-developer-guide/blob/master/doc_source/how-to-integrate-an-existing-bucket.rst


### iOS

No configuration required - the plugin should work out of the box.          

### Authors
```
the plugin is created and maintained by fäm properties.
Android version written by Prachi Shrivastava
IOS version written by Prachi Shrivastava
```
