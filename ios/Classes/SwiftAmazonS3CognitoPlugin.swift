import Flutter
import UIKit
import AWSS3
import AWSCore
import MobileCoreServices

public class SwiftAmazonS3CognitoPlugin: NSObject, FlutterPlugin {

    var channel:FlutterMethodChannel
    var region1:AWSRegionType = AWSRegionType.USEast1
    var subRegion1:AWSRegionType = AWSRegionType.EUWest1

    init(channel: FlutterMethodChannel){
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "amazon_s3_cognito", binaryMessenger: registrar.messenger())
        let instance = SwiftAmazonS3CognitoPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private func sendLogToFlutter(_ message: String) {
        print(message)
        channel.invokeMethod("nativeLog", arguments: message)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        sendLogToFlutter("🔵 [iOS] Método llamado: \(call.method)")

        if (call.method.elementsEqual("uploadImageToAmazon")) {
            sendLogToFlutter("🚀 [iOS] Iniciando proceso de upload...")

            guard let arguments = call.arguments as? NSDictionary else {
                sendLogToFlutter("❌ [iOS] Error: No se pudieron parsear los argumentos")
                result(FlutterError(code: "PARSE_ERROR", message: "No se pudieron parsear los argumentos", details: nil))
                return
            }

            guard let imagePath = arguments["filePath"] as? String,
                  let bucket = arguments["bucket"] as? String,
                  let identity = arguments["identity"] as? String else {
                sendLogToFlutter("❌ [iOS] Error: Parámetros faltantes o inválidos")
                sendLogToFlutter("   - filePath: \(arguments["filePath"] ?? "nil")")
                sendLogToFlutter("   - bucket: \(arguments["bucket"] ?? "nil")")
                sendLogToFlutter("   - identity: \(arguments["identity"] ?? "nil")")
                result(FlutterError(code: "MISSING_PARAMS", message: "Parámetros faltantes", details: nil))
                return
            }

            sendLogToFlutter("📁 [iOS] FilePath: \(imagePath)")
            sendLogToFlutter("🗄️  [iOS] Bucket: \(bucket)")
            sendLogToFlutter("🆔 [iOS] Identity Pool: \(identity)")

            // IMPORTANTE: Verificar si el Identity Pool ID tiene el formato correcto
            if !identity.contains(":") {
                sendLogToFlutter("⚠️  [iOS] ADVERTENCIA: El Identity Pool ID no tiene formato válido (debe ser región:id)")
                sendLogToFlutter("⚠️  [iOS] Formato esperado: us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
            }

            // Extraer la región del Identity Pool ID
            let identityRegion = identity.split(separator: ":").first ?? ""
            sendLogToFlutter("🌎 [iOS] Región extraída del Identity Pool: \(identityRegion)")

            if identityRegion == "us-east-2" {
                sendLogToFlutter("⚠️  [iOS] PROBLEMA DETECTADO: El Identity Pool está en us-east-2")
                sendLogToFlutter("⚠️  [iOS] PERO el código está configurado para usar US_EAST_1 (us-east-1)")
                sendLogToFlutter("⚠️  [iOS] Esta diferencia de regiones puede causar errores de autenticación!")
            }

            var bucketParts = bucket.split(separator: "/");
            let bucketRoot = String(bucketParts.remove(at: 0));
            let bucketPath = bucketParts.joined(separator: "/")

            sendLogToFlutter("📦 [iOS] Bucket root: \(bucketRoot)")
            sendLogToFlutter("📂 [iOS] Bucket path: \(bucketPath)")

            let fileUrl = URL(fileURLWithPath: imagePath)
            sendLogToFlutter("🔗 [iOS] File URL: \(fileUrl.absoluteString)")

            // Verificar si el archivo existe
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: imagePath) {
                sendLogToFlutter("✅ [iOS] El archivo existe")
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: imagePath)
                    let fileSize = attributes[.size] as? UInt64 ?? 0
                    sendLogToFlutter("📏 [iOS] Tamaño del archivo: \(fileSize) bytes")
                } catch {
                    sendLogToFlutter("⚠️  [iOS] No se pudieron obtener los atributos del archivo: \(error)")
                }
            } else {
                sendLogToFlutter("❌ [iOS] El archivo NO existe en la ruta: \(imagePath)")
                result(FlutterError(code: "FILE_NOT_FOUND", message: "El archivo no existe", details: imagePath))
                return
            }

            sendLogToFlutter("🔧 [iOS] Configurando AWS...")
            if (AWSServiceManager.default().defaultServiceConfiguration == nil) {
                sendLogToFlutter("🔑 [iOS] Creando credentialsProvider...")

                // Detectar la región desde el Identity Pool ID
                var cognitoRegion: AWSRegionType = .USEast1
                if identityRegion == "us-east-2" {
                    cognitoRegion = .USEast2
                    sendLogToFlutter("🌎 [iOS] Región AUTO-DETECTADA: USEast2 (us-east-2)")
                } else if identityRegion == "us-east-1" {
                    cognitoRegion = .USEast1
                    sendLogToFlutter("🌎 [iOS] Región AUTO-DETECTADA: USEast1 (us-east-1)")
                } else if identityRegion == "us-west-1" {
                    cognitoRegion = .USWest1
                    sendLogToFlutter("🌎 [iOS] Región AUTO-DETECTADA: USWest1 (us-west-1)")
                } else if identityRegion == "us-west-2" {
                    cognitoRegion = .USWest2
                    sendLogToFlutter("🌎 [iOS] Región AUTO-DETECTADA: USWest2 (us-west-2)")
                } else if identityRegion == "eu-west-1" {
                    cognitoRegion = .EUWest1
                    sendLogToFlutter("🌎 [iOS] Región AUTO-DETECTADA: EUWest1 (eu-west-1)")
                } else {
                    sendLogToFlutter("⚠️  [iOS] Región no reconocida: \(identityRegion), usando USEast1 por defecto")
                }

                // Intentar crear el credentials provider y capturar errores
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType: cognitoRegion, identityPoolId: identity)

                sendLogToFlutter("⚙️  [iOS] Creando configuration con región: \(cognitoRegion.rawValue)")
                let configuration = AWSServiceConfiguration(region: cognitoRegion, credentialsProvider:credentialsProvider)
                AWSServiceManager.default().defaultServiceConfiguration = configuration

                sendLogToFlutter("🚀 [iOS] Registrando AWSS3TransferUtility...")
                let tuConf = AWSS3TransferUtilityConfiguration()
                tuConf.isAccelerateModeEnabled = false
                AWSS3TransferUtility.register(
                    with: configuration!,
                    transferUtilityConfiguration: tuConf,
                    forKey: "transfer-utility-with-advanced-options"
                )
                sendLogToFlutter("✅ [iOS] AWS configurado exitosamente")
            } else {
                sendLogToFlutter("ℹ️  [iOS] AWS ya estaba configurado previamente")
            }

            guard let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: "transfer-utility-with-advanced-options") else {
                sendLogToFlutter("❌ [iOS] Error CRÍTICO: No se pudo obtener transferUtility")
                result(FlutterError(code: "TRANSFER_UTILITY_ERROR", message: "No se pudo obtener TransferUtility", details: nil))
                return
            }
            sendLogToFlutter("✅ [iOS] TransferUtility obtenido exitosamente")

            sendLogToFlutter("📊 [iOS] Configurando expression para progreso...")
            var  theProgress:Double = 0.0;
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = {(task, progress) in
                DispatchQueue.main.async(execute: {
                    theProgress = progress.fractionCompleted;
                    let progressPercent = progress.fractionCompleted * 100
                    self.sendLogToFlutter("📈 [iOS] Progreso: \(String(format: "%.2f", progressPercent))%")
                    self.channel.invokeMethod("progress", arguments: progressPercent)
                })
            }

            let fileName = bucketPath + "/" + NSUUID().uuidString + "." + fileExtensionForPath(path: imagePath)
            sendLogToFlutter("🏷️  [iOS] Nombre del archivo generado: \(fileName)")

            sendLogToFlutter("🔧 [iOS] Configurando completion handler...")
            var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
            completionHandler = { (task, error) -> Void in
                DispatchQueue.main.async(execute: {
                    self.sendLogToFlutter("🏁 [iOS] Completion handler llamado")
                    if let error = error {
                        self.sendLogToFlutter("❌ [iOS] Upload FALLÓ con error")
                        self.sendLogToFlutter("❌ [iOS] Error description: \(error.localizedDescription)")
                        self.sendLogToFlutter("❌ [iOS] Error domain: \((error as NSError).domain)")
                        self.sendLogToFlutter("❌ [iOS] Error code: \((error as NSError).code)")
                        self.sendLogToFlutter("❌ [iOS] Error userInfo: \((error as NSError).userInfo)")

                        // Mensajes específicos según el tipo de error
                        let nsError = error as NSError
                        if nsError.domain == "com.amazonaws.AWSS3TransferUtilityErrorDomain" {
                            self.sendLogToFlutter("❌ [iOS] Error de AWS S3 Transfer Utility")
                        } else if nsError.domain == "com.amazon.cognito.identity" {
                            self.sendLogToFlutter("❌ [iOS] Error de autenticación con Cognito Identity")
                            self.sendLogToFlutter("❌ [iOS] Verifica que el Identity Pool ID y la región sean correctos")
                        }

                        result(FlutterError(code: "UPLOAD_FAILED",
                                          message: error.localizedDescription,
                                          details: "\(nsError.domain) - Code: \(nsError.code)"))
                    } else if (theProgress < 1.0) {
                        self.sendLogToFlutter("❌ [iOS] Error: Upload nunca terminó de cargar")
                        self.sendLogToFlutter("❌ [iOS] Progreso final: \(theProgress * 100)%")
                        result(FlutterError(code: "UPLOAD_INCOMPLETE", message: "El upload no se completó", details: nil))
                    } else {
                        let imageAmazonUrl = "https://s3.amazonaws.com/\(bucketRoot)/\(fileName)"
                        self.sendLogToFlutter("✅ [iOS] Upload COMPLETADO exitosamente!")
                        self.sendLogToFlutter("🔗 [iOS] URL generada: \(imageAmazonUrl)")
                        result(imageAmazonUrl);
                    }
                })
            }

            sendLogToFlutter("📖 [iOS] Leyendo datos del archivo...")
            var fileData:Data? = nil;
            do{
                fileData = try Data(contentsOf: fileUrl)
                sendLogToFlutter("✅ [iOS] Datos del archivo leídos: \(fileData?.count ?? 0) bytes")
            } catch {
                sendLogToFlutter("❌ [iOS] Error al leer archivo: \(error.localizedDescription)")
                result(FlutterError(code: "FILE_READ_ERROR", message: error.localizedDescription, details: nil))
                return
            }

            guard let fileData = fileData else {
                sendLogToFlutter("❌ [iOS] fileData es nil después de leer")
                result(FlutterError(code: "FILE_DATA_NULL", message: "Los datos del archivo son nulos", details: nil))
                return
            }

            let contentType = mimeTypeForPath(path: imagePath);
            sendLogToFlutter("📋 [iOS] Content-Type: \(contentType)")
            sendLogToFlutter("🏷️  [iOS] Nombre final del archivo: \(fileName)")
            sendLogToFlutter("🗄️  [iOS] Bucket destino: \(bucketRoot)")

            sendLogToFlutter("🚀 [iOS] Iniciando uploadData...")
            transferUtility.uploadData(fileData,
                                        bucket: bucketRoot,
                                        key: fileName,
                                        contentType: contentType,
                                        expression: expression,
                                        completionHandler: completionHandler).continueWith {
                                            (task) -> AnyObject? in
                                            if let error = task.error {
                                                self.sendLogToFlutter("❌ [iOS] Error en continueWith: \(error.localizedDescription)")
                                                self.sendLogToFlutter("❌ [iOS] Error domain: \((error as NSError).domain)")
                                                self.sendLogToFlutter("❌ [iOS] Error code: \((error as NSError).code)")
                                                result(FlutterError(code: "CONTINUE_WITH_ERROR",
                                                                  message: error.localizedDescription,
                                                                  details: nil));
                                            }

                                            if let _ = task.result {
                                                self.sendLogToFlutter("📤 [iOS] Upload iniciado correctamente, esperando completación...")
                                            }
                                            return nil;
            }
            //}
        } else if(call.method.elementsEqual("uploadImage")) {
            //uploadImageForRegion(call,result: result)
        } else if(call.method.elementsEqual("deleteImage")) {
            //deleteImage(call,result: result)
        }
    }

    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

    func fileExtensionForPath(path: String) -> String{
        let ext =  path.split(separator: ".").last ?? ""
        return String(ext)
    }

    public func initRegions(region:String,subRegion:String){
        region1 = getRegion(name: region)
        subRegion1 = getRegion(name: subRegion)
    }

    public func getRegion( name:String ) -> AWSRegionType{
        if (name == "US_EAST_1") {
            return AWSRegionType.USEast1
        } else if(name == "AP_SOUTHEAST_1") {
            return AWSRegionType.APSoutheast1
        } else if(name == "US_EAST_2") {
            return AWSRegionType.USEast2
        } else if(name == "EU_WEST_1") {
            return AWSRegionType.EUWest1
        } else if(name == "CA_CENTRAL_1") {
            return AWSRegionType.CACentral1
        } else if(name == "CN_NORTH_1") {
            return AWSRegionType.CNNorth1
        } else if(name == "CN_NORTHWEST_1") {
            return AWSRegionType.CNNorthWest1
        } else if(name == "EU_CENTRAL_1") {
            return AWSRegionType.EUCentral1
        } else if(name == "EU_WEST_2"){
            return AWSRegionType.EUWest2
        } else if(name == "EU_WEST_3") {
            return AWSRegionType.EUWest3
        } else if(name == "SA_EAST_1") {
            return AWSRegionType.SAEast1
        } else if(name == "US_WEST_1") {
            return AWSRegionType.USWest1
        } else if(name == "US_WEST_2") {
            return AWSRegionType.USWest2
        } else if(name == "AP_NORTHEAST_1") {
            return AWSRegionType.APNortheast1
        } else if(name == "AP_NORTHEAST_2") {
            return AWSRegionType.APNortheast2
        } else if(name == "AP_SOUTHEAST_1") {
            return AWSRegionType.APSoutheast1
        } else if(name == "AP_SOUTHEAST_2") {
            return AWSRegionType.APSoutheast2
        } else if(name == "AP_SOUTH_1") {
            return AWSRegionType.APSouth1
        } else if(name == "ME_SOUTH_1") {
            return AWSRegionType.MESouth1
        }
        return AWSRegionType.Unknown
    }
}
