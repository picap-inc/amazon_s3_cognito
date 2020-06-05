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

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method.elementsEqual("uploadImageToAmazon")){
            let arguments = call.arguments as! NSDictionary
            let imagePath = arguments["filePath"] as! String
            let bucket = arguments["bucket"] as! String
            let identity = arguments["identity"] as! String

            var bucketParts = bucket.split(separator: "/");
            let bucketRoot = String(bucketParts.remove(at: 0));
            let bucketPath = bucketParts.joined(separator: "/")

            let fileUrl = URL(fileURLWithPath: imagePath)
            if(AWSServiceManager.default().defaultServiceConfiguration == nil){
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId: identity)
                let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                AWSServiceManager.default().defaultServiceConfiguration = configuration
                let tuConf = AWSS3TransferUtilityConfiguration()
                tuConf.isAccelerateModeEnabled = false
                AWSS3TransferUtility.register(
                    with: configuration!,
                    transferUtilityConfiguration: tuConf,
                    forKey: "transfer-utility-with-advanced-options"
                )
            }
            let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: "transfer-utility-with-advanced-options")

            var  theProgress:Double = 0.0;
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = {(task, progress) in
                DispatchQueue.main.async(execute: {
                    theProgress = progress.fractionCompleted;
                    self.channel.invokeMethod("progress", arguments: progress.fractionCompleted*100)
                })
            }

            let fileName = bucketPath + "/" + NSUUID().uuidString + "." + fileExtensionForPath(path: imagePath)
            //let imageData = image.jpegData(compressionQuality: 0.9)

            var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
            completionHandler = { (task, error) -> Void in
                DispatchQueue.main.async(execute: {
                    if (error != nil){
                        print("Error: \(error?.localizedDescription)")
                        result(nil)
                    }else if (theProgress < 1.0){
                        print("Error: nunca terminó de cargar")
                        result(nil)
                    }else{
                        let imageAmazonUrl = "https://s3.amazonaws.com/\(bucketRoot)/\(fileName)"
                        result(imageAmazonUrl);
                    }
                })
            }

            var fileData:Data? = nil;
            do{
                fileData = try Data(contentsOf: fileUrl)
            } catch  {

            }
            let contentType = mimeTypeForPath(path: imagePath);
            print("--------------")
            print(contentType)
            print(fileName)
            transferUtility?.uploadData(fileData!,
                                        bucket: bucketRoot,
                                        key: fileName,
                                        contentType: contentType,
                                        expression: expression,
                                        completionHandler: completionHandler).continueWith {
                                            (task) -> AnyObject? in
                                            if let error = task.error {
                                                print("Error: \(error.localizedDescription)")
                                                result(nil);
                                            }

                                            if let _ = task.result {
                                                print ("uploading ..............")
                                            }
                                            return nil;
            }

            //}
        }else if(call.method.elementsEqual("uploadImage")){
            //uploadImageForRegion(call,result: result)
        }else if(call.method.elementsEqual("deleteImage")){
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

        if(name == "US_EAST_1"){
            return AWSRegionType.USEast1
        }else if(name == "AP_SOUTHEAST_1"){
            return AWSRegionType.APSoutheast1
        }else if(name == "US_EAST_2"){
            return AWSRegionType.USEast2
        }else if(name == "EU_WEST_1"){
            return AWSRegionType.EUWest1
        }else if(name == "CA_CENTRAL_1"){
            return AWSRegionType.CACentral1
        }else if(name == "CN_NORTH_1"){
            return AWSRegionType.CNNorth1
        } else if(name == "CN_NORTHWEST_1"){
            return AWSRegionType.CNNorthWest1
        }else if(name == "EU_CENTRAL_1"){
            return AWSRegionType.EUCentral1
        } else if(name == "EU_WEST_2"){
            return AWSRegionType.EUWest2
        }else if(name == "EU_WEST_3"){
            return AWSRegionType.EUWest3
        } else if(name == "SA_EAST_1"){
            return AWSRegionType.SAEast1
        } else if(name == "US_WEST_1"){
            return AWSRegionType.USWest1
        }else if(name == "US_WEST_2"){
            return AWSRegionType.USWest2
        } else if(name == "AP_NORTHEAST_1"){
            return AWSRegionType.APNortheast1
        } else if(name == "AP_NORTHEAST_2"){
            return AWSRegionType.APNortheast2
        } else if(name == "AP_SOUTHEAST_1"){
            return AWSRegionType.APSoutheast1
        }else if(name == "AP_SOUTHEAST_2"){
            return AWSRegionType.APSoutheast2
        } else if(name == "AP_SOUTH_1"){
            return AWSRegionType.APSouth1
        }else if(name == "ME_SOUTH_1"){
            return AWSRegionType.MESouth1
        }

        return AWSRegionType.Unknown

    }
}
