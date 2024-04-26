# Amazon S3 Cognito

Complemento de Amazon S3 para Flutter

Complemento no oficial de Amazon S3 escrito en Dart para Flutter.

Este plugin nace del repositorio [AmazonS3Cognito](https://github.com/prachiFam/amazon_s3_cognito) de PrachiFam

## Index
* [Como usar](#usage)
    * [Demo](#demo)
* [Instalación](#installation)
    * [Android](#nativeAndroid)
    * [iOS](#nativeiOS)
* [Colaboradores](#contributors)


<a name="usage"></a>
## Como usar
Para usar este complemento, agregue `amazon_s3_cognito` como dependencia en su archivo pubspec.yaml


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


// Utilice el siguiente código para especificar la región y subregión para cargar imágenes
String uploadedImageUrl = await AmazonS3Cognito.upload(
            _image.path,
            BUCKET_NAME,
            IDENTITY_POOL_ID,
            IMAGE_NAME,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)                                            

```

<a name="installation"></a>
## Instalación

<a name="nativeAndroid"></a>
### Android

Agrega [awsconfiguration.json](https://github.com/picap-inc/amazon_s3_cognito/blob/main/example/android/app/src/main/res/raw/awsconfiguration.json) a tu proyecto android en una carpeta raw en res

<a name="nativeiOS"></a>
### iOS

No se requiere configuración: el complemento debería funcionar de inmediato.

<a name="contributors"></a>
## Colaboradores

| Desarrolladores  |  |
|------------------| ------------- |
| Daniel Rodriguez | <a href="https://github.com/dabeto"><img src="https://avatars.githubusercontent.com/u/2546455?v=4" width="50" height="50" /></a>  |
| Juan Labrador    | <a href="https://github.com/juanlabrador"><img src="https://avatars.githubusercontent.com/u/6761048" width="50" height="50" /></a>  |
| Martin Escobar   | <a href="https://github.com/martinale14"><img src="https://avatars.githubusercontent.com/u/56127727?v=4" width="50" height="50" /></a>  |
