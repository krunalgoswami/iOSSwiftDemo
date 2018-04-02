import Alamofire
import AlamofireJsonToObjects
import MBProgressHUD

class NetworkManager: SessionManager {
    static var networkManager : NetworkManager?
    typealias NetworkResponse = (Any?,Error?) -> Void
    var headers = HTTPHeaders()
    
    struct kContentType {
        static let AppJson = "application/json"
        static let AppXUrlencoded = "application/x-www-form-urlencoded"
        static let AppFormData = "multipart/form-data"
        
    }
    
    class func sharedInstance() -> NetworkManager {
        if (networkManager == nil) {
            let configuration = URLSessionConfiguration.default
            networkManager = NetworkManager(configuration: configuration)
        }
        return networkManager!;
    }
    
    // MARK: - Get Mehtod
    func makeGetRequestToUrl<T:EVNetworkingObject> (Url url : String , Parameters  params: [String: Any], modelType:T , showHud:Bool = true, isBackOnailure:Bool = false, Callback callback :@escaping (Any?,Error?)-> Void) -> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        self.request(url, method: .get, parameters: params, encoding: URLEncoding(destination: .methodDependent), headers: headers)
            .validate(statusCode: [200])
            .validate(contentType: [kContentType.AppJson])
            .responseObject(completionHandler: { (response:DataResponse<T>) in
                Utility.hideProgressHUD()
                if response.result.isSuccess{
                    if let responseMoldel = response.result.value{
                        if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                            callback(responseMoldel as Any,nil)
                        } else {
                            print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                        }
                    }
                } else {
                    if response.error!._code == NSURLErrorTimedOut {
                        Utility.showToastMessage(kToast.General.RequestTimedOut)
                    }else {
                        do {
                            let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                            if response.response?.statusCode == 401{
                                print("session expired")
                                Utility.clearUserDefaultData()
                                Utility.setupRootViewController()
                                return
                            } else if response.response?.statusCode == 422 && isBackOnailure , let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"]{
                                callback(nil, Utility.getError(code: 422, message: error))
                            } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                Utility.showToastMessage(error)
                            } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                Utility.showToastMessage(message)
                            } else {
                                Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                            }
                        }catch{
                            Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                        }
                        if isBackOnailure{
                            print(response.error ?? Error.self)
                            if let objError = response.error as NSError?, objError.code == NSURLErrorNotConnectedToInternet{
                                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
                            } else {
                                callback(nil, Utility.getError(code: 0, message: kToast.General.AppUnderMaintainance))
                            }
                        }
                    }
                }
            })
    }
    
    // MARK: - Post Method
    func makePostRequestToUrl<T:EVNetworkingObject> (Url url:String, Parameters params: [String: Any], modelType:T, showHud:Bool = true, isBackOnailure:Bool = false, Callback callback:@escaping (Any?,Error?) -> Void)-> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        self.request(url, method: .post, parameters: params, encoding:URLEncoding(destination: .methodDependent), headers: headers)
            .validate(statusCode: [200])
            .validate(contentType: [kContentType.AppJson])
            .responseObject(completionHandler: { (response:DataResponse<T>) in
                Utility.hideProgressHUD()
                if response.result.isSuccess{
                    if let responseMoldel = response.result.value{
                        if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                            callback(responseMoldel as Any,nil)
                        } else {
                            print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                        }
                    }
                } else {
                    if response.error!._code == NSURLErrorTimedOut {
                        Utility.showToastMessage(kToast.General.RequestTimedOut)
                    }else {
                        do {
                            let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                            if response.response?.statusCode == 401{
                                print("session expired")
                                Utility.clearUserDefaultData()
                                Utility.setupRootViewController()
                                return
                            } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                Utility.showToastMessage(error)
                            } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                Utility.showToastMessage(message)
                            } else {
                                Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                            }
                        }catch{
                            Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                        }
                    }
                    if isBackOnailure{
                        callback(nil, response.error)
                    }
                }
            })
    }
    
    // MARK: - Multipart Post Mehtod
    func makePostMultipartRequestToUrl<T:EVNetworkingObject> (Url url:String, Parameters params: [String: Any], ArrayMultipartData arrayMultipartData: [MultipartData], modelType:T, showHud:Bool = true, isBackOnailure:Bool = false, Callback callback:@escaping (Any?,Error?) -> Void)-> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        
        self.upload(multipartFormData: { (multipartFormData) in
            //Multi Media Parameters
            for multipartData in arrayMultipartData{
                let trimmWhiteSpaceImageName:String = multipartData.name.replacingOccurrences(of: " ", with: "")

                switch multipartData.type{
                case enumMultipartDataType.Image.value:
                    var imgData:Data?
                    switch multipartData.mimeType{
                    case enumMultipartDataMimeType.ImagePng.value:
                        imgData = UIImagePNGRepresentation(multipartData.media.image)
                    case enumMultipartDataMimeType.ImageJpg.value:
                        imgData = UIImageJPEGRepresentation(multipartData.media.image, 1)
                    default:
                        print("Invalid Mime Type")
                        break
                    }
                    
                    if let imageData = imgData{
                        multipartFormData.append(imageData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                case enumMultipartDataType.Video.value:
                    if let videoData = try? Data.init(contentsOf: multipartData.media.video as URL){
                        multipartFormData.append(videoData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                case enumMultipartDataType.Audio.value:
                    if let audioData = try? Data(contentsOf: multipartData.media.audio as URL, options: Data.ReadingOptions()){
                        multipartFormData.append(audioData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                case enumMultipartDataType.File.value:
                        multipartFormData.append(multipartData.media.AdobeFile, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                default:
                    print("Error in attachment Type")
                }
            }
            
            //Normal Parameters
            for (key, value) in params {
                if let data = (value as AnyObject).data(using: String.Encoding.utf8.rawValue){
                    multipartFormData.append(data, withName: key)
                }
            }
        }, to: url, headers: headers) { (multipartFormDataEncodingResult) in
            switch multipartFormDataEncodingResult{
            case .success(let uploadedData, _, _):
                uploadedData
                    .validate(statusCode: [200])
                    .validate(contentType: [kContentType.AppJson])
                    .responseObject(completionHandler: { (response:DataResponse<T>) in
                        Utility.hideProgressHUD()
                        if response.result.isSuccess{
                            if let responseMoldel = response.result.value{
                                if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                                    callback(responseMoldel as Any,nil)
                                } else {
                                    print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                                }
                            }
                        } else {
                            if response.error!._code == NSURLErrorTimedOut {
                                Utility.showToastMessage(kToast.General.RequestTimedOut)
                            }else {
                                do {
                                    let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                                    if response.response?.statusCode == 401{
                                        print("session expired")
                                        Utility.clearUserDefaultData()
                                        Utility.setupRootViewController()
                                        return
                                    } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                        Utility.showToastMessage(error)
                                    } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                        Utility.showToastMessage(message)
                                    } else {
                                        Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                                    }
                                }catch{
                                    Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                                }
                            }
                            if isBackOnailure{
                                callback(nil, response.error)
                            }
                        }
                    })
            case .failure(let error):
                if error._code == NSURLErrorTimedOut {
                    Utility.showToastMessage(kToast.General.RequestTimedOut)
                }else {
                    Utility.showToastMessage(error.localizedDescription)
                }
                if isBackOnailure{
                    callback(nil, error)
                }
            }
        }
    }
    
    // MARK: - Put Mehtod
    func makePutRequestToUrl<T:EVNetworkingObject> (Url url : String , Parameters  params: [String: Any], modelType:T, showHud:Bool = true, isBackOnailure:Bool = false, Callback callback :@escaping (Any?,Error?) -> Void)-> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        self.request(url, method: .put, parameters: params, encoding: URLEncoding(destination: .methodDependent), headers: headers)
            .validate(statusCode: [200])
            .validate(contentType: [kContentType.AppJson])
            .responseObject(completionHandler: { (response:DataResponse<T>) in
                Utility.hideProgressHUD()
                if response.result.isSuccess{
                    if let responseMoldel = response.result.value{
                        if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                            callback(responseMoldel as Any,nil)
                        } else {
                            print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                        }
                    }
                } else {
                    if response.error!._code == NSURLErrorTimedOut {
                        Utility.showToastMessage(kToast.General.RequestTimedOut)
                    } else {
                        do {
                            let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                            if response.response?.statusCode == 401{
                                print("session expired")
                                Utility.clearUserDefaultData()
                                Utility.setupRootViewController()
                                return
                            } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                Utility.showToastMessage(error)
                            } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                Utility.showToastMessage(message)
                            } else {
                                Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                            }
                        } catch {
                            Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                        }
                    }
                    if isBackOnailure{
                        callback(nil, response.error)
                    }
                }
            })
    }
    
    // MARK: - Multipart Put Mehtod
    func makePutMultipartRequest<T:EVNetworkingObject> (Url url:String, Parameters params: [String: Any], ArrayMultipartData arrayMultipartData: [MultipartData], modelType:T, showHud:Bool = true, isBackOnailure:Bool = false, Callback callback:@escaping (Any?,Error?) -> Void)-> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        
        self.upload(multipartFormData: { (multipartFormData) in
            //Multi Media Parameters
            for multipartData in arrayMultipartData{
                let trimmWhiteSpaceImageName:String = multipartData.name.replacingOccurrences(of: " ", with: "")
                switch multipartData.type{
                case enumMultipartDataType.Image.value:
                    var imgData:Data?
                    switch multipartData.mimeType{
                    case enumMultipartDataMimeType.ImagePng.value:
                        imgData = UIImagePNGRepresentation(multipartData.media.image)
                    case enumMultipartDataMimeType.ImageJpg.value:
                        imgData = UIImageJPEGRepresentation(multipartData.media.image, 1)
                    default:
                        print("Invalid Mime Type")
                        break
                    }
                    
                    if let imageData = imgData{
                        multipartFormData.append(imageData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                case enumMultipartDataType.Video.value:
                    if let videoData = try? Data.init(contentsOf: multipartData.media.video as URL){
                        multipartFormData.append(videoData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                case enumMultipartDataType.Audio.value:
                    if let audioData = try? Data(contentsOf: multipartData.media.audio as URL, options: Data.ReadingOptions()){
                        multipartFormData.append(audioData, withName: multipartData.key, fileName: trimmWhiteSpaceImageName, mimeType: multipartData.mimeType)
                    }
                default:
                    print("Error in attachment Type")
                }
            }
            
            //Normal Parameters
            for (key, value) in params {
                if let data = (value as AnyObject).data(using: String.Encoding.utf8.rawValue){
                    multipartFormData.append(data, withName: key)
                }
            }
        }, to: url, method: .put, headers: headers) { (multipartFormDataEncodingResult) in
            switch multipartFormDataEncodingResult{
            case .success(let uploadedData, _, _):
                uploadedData
                    .validate(statusCode: [200])
                    .validate(contentType: [kContentType.AppJson])
                    .responseObject(completionHandler: { (response:DataResponse<T>) in
                        Utility.hideProgressHUD()
                        if response.result.isSuccess{
                            if let responseMoldel = response.result.value{
                                if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                                    callback(responseMoldel as Any,nil)
                                } else {
                                    print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                                }
                            }
                        } else {
                            if response.error!._code == NSURLErrorTimedOut {
                                Utility.showToastMessage(kToast.General.RequestTimedOut)
                            } else {
                                do {
                                    let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                                    if response.response?.statusCode == 401{
                                        print("session expired")
                                        Utility.clearUserDefaultData()
                                        Utility.setupRootViewController()
                                        return
                                    } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                        Utility.showToastMessage(error)
                                    } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                        Utility.showToastMessage(message)
                                    } else {
                                        Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                                    }
                                }catch{
                                    Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                                }
                            }
                            if isBackOnailure{
                                callback(nil, response.error)
                            }
                        }
                    })
            case .failure(let error):
                if error._code == NSURLErrorTimedOut {
                    Utility.showToastMessage(kToast.General.RequestTimedOut)
                }else {
                    Utility.showToastMessage(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Delete Method
    func makeDeleteRequestToUrl<T:EVNetworkingObject> (Url url:String, Parameters params: [String: Any], modelType:T, showHud:Bool = true, isBackOnailure:Bool = false, Callback callback:@escaping (Any?,Error?) -> Void)-> Void {
        if !Reachability.isInternetAvailable() {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
            if isBackOnailure{
                callback(nil, Utility.getError(code: NSURLErrorNotConnectedToInternet, message: kToast.General.CheckInternetConnection))
            }
            return
        }
        setAuthorizationHeaderIfAvailable()
        if showHud{ Utility.showProgressHUD()   }
        self.request(url, method: .delete, parameters: params, encoding:URLEncoding(destination: .methodDependent), headers: headers)
            .validate(statusCode: [200])
            .validate(contentType: [kContentType.AppJson])
            .responseObject(completionHandler: { (response:DataResponse<T>) in
                Utility.hideProgressHUD()
                if response.result.isSuccess{
                    if let responseMoldel = response.result.value{
                        if (response.result.value as! Base).payload.classForCoder == Base.payloadData.classForCoder{
                            callback(responseMoldel as Any,nil)
                        } else {
                            print("-----> ResponseModel is Conflig wigth Base.payloadData Model. BaseModel -> \(Base.payloadData.classForCoder) & ResponseModel -> \((response.result.value as! Base).payload.classForCoder)")
                        }
                    }
                } else {
                    if response.error!._code == NSURLErrorTimedOut {
                        Utility.showToastMessage(kToast.General.RequestTimedOut)
                    } else {
                        do {
                            let dictData  = try JSONSerialization.jsonObject(with: response.data!, options: JSONSerialization.ReadingOptions.allowFragments)
                            if response.response?.statusCode == 401{
                                print("session expired")
                                Utility.clearUserDefaultData()
                                Utility.setupRootViewController()
                                return
                            } else if let error = ((dictData as? [String:Any] ?? [:])["payload"] as? [String:String] ?? [:])["error"] {
                                Utility.showToastMessage(error)
                            } else if let message = (dictData as? [String:Any] ?? [:])["message"] as? String{
                                Utility.showToastMessage(message)
                            } else {
                                Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                            }
                        } catch {
                            Utility.showToastMessage(kToast.General.AppUnderMaintainance)
                        }
                    }
                    if isBackOnailure{
                        callback(nil, response.error)
                    }
                }
            })
    }
    
    // MARK: - Download Mehtod
    func downloadFile(paramDic:NSDictionary,strUrl:String,Callback callback :@escaping NetworkResponse)  {
        Utility.showProgressHUD()
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let dateFormater = DateFormatter()
        let todayDate = Date()
        
        Alamofire.download(
            strUrl,
            method: .post,
            parameters: paramDic as? Parameters ?? [:],
            encoding: JSONEncoding.default,
            headers: ["Authorization": "bearer " + kStorage.token],
            to: destination).downloadProgress(closure: { (progress) in
                print(progress.fractionCompleted*100)
            }).response(completionHandler: { (DefaultDownloadResponse) in
                Utility.hideProgressHUD()
                let filemgr = FileManager.default
                
                // Create a new folder in the directory named "current date"
                let documentsPathWithCurrentDate = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                let currentDateWithAppendedPath = documentsPathWithCurrentDate.appendingPathComponent("\(String(describing: dateFormater.string(from: todayDate)))/")
                do {
                    try FileManager.default.createDirectory(atPath: currentDateWithAppendedPath!.path, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("Unable to create directory \(error.debugDescription)")
                }
                
                // Then check if the fileURL directory exists. If not, create it
                let docsDirURL = try! filemgr.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL = docsDirURL.appendingPathComponent("\(String(describing: dateFormater.string(from: todayDate)))/")
                if !filemgr.fileExists(atPath: docsDirURL.path) {
                    do {
                        try filemgr.createDirectory(at: fileURL, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        print("Unable to create directory \(error.debugDescription)")
                        return
                    }
                }
                
                // Move file from document to date Folder
                let fileName = DefaultDownloadResponse.destinationURL!.lastPathComponent
                let defaultDocSaveFileURL = DefaultDownloadResponse.destinationURL!
                let saveFileURL = fileURL.appendingPathComponent(fileName)
                if !filemgr.fileExists(atPath: saveFileURL.path) {
                    do {
                        try filemgr.moveItem(at: defaultDocSaveFileURL, to: saveFileURL)
                    } catch let error as NSError {
                        print("Unable to move file \(error.debugDescription)")
                    }
                }else{
                    // here overiwrite with latest download file  for that first remove and then again save at curent date folder
                    do {
                        try filemgr.removeItem(atPath: saveFileURL.path)
                    } catch let error as NSError {
                        print("Unable to delete file \(error.debugDescription)")
                    }
                    do {
                        try filemgr.moveItem(at: defaultDocSaveFileURL, to: saveFileURL)
                    } catch let error as NSError {
                        print("Unable to move file \(error.debugDescription)")
                    }
                }
                
                // removed default saved file in documnet dicrectory after moved current date folder
                if filemgr.fileExists(atPath: defaultDocSaveFileURL.path) {
                    do {
                        try filemgr.removeItem(atPath: defaultDocSaveFileURL.path)
                    } catch let error as NSError {
                        print("Unable to delete file \(error.debugDescription)")
                    }
                }
                callback(saveFileURL,nil)
            })
    }
    
    // MARK: - Set Headers
    func setAuthorizationHeaderIfAvailable() -> Void{
        headers["Accept"] =  kContentType.AppJson
        headers["Content-Type"] =  kContentType.AppXUrlencoded
        headers["Authorization"] = Utility.checkEmpty(kStorage.token) ? kSecret.staticToken : kStorage.token
        headers["deviceId"] = (UIDevice.current.identifierForVendor?.uuidString.replacingOccurrences(of: "-", with: ""))!
    }
    
}
