import UIKit
import MBProgressHUD
import UserNotifications
import PusherSwift
import Stripe
import Fabric
import Crashlytics
import Photos

class Utility:NSObject {
    
    // MARK:- Variables
    typealias UIAlertTapCompletionBlock = (_ alertViewController: UIAlertController , _ buttonIndex: Int) -> Void
    
    static var hud:MBProgressHUD?
    static var alertViewController:UIAlertController!
    static let networkManager = NetworkManager.sharedInstance()
    
    static private var totalRecordsInPage = Int(20) + 1
    static private var pageCurrent = Int(1)
    static private var pageTotal = Int(0)
    static var timer = Timer()
    private static var timerCounter = 0
    static var countryTotalRecords = Int(0)
    
    
    // MARK:- Timer & Timeout mehtods for socket connection Issue
    static func resetTimer(_ on:Bool) {
        if on{
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(Utility.checkTimeoutStatus), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .commonModes)
        } else {
            timer.invalidate()
            Utility.timerCounter = 0
        }
    }
    
    static func checkTimeoutStatus() {
        Utility.timerCounter += 1
        print("timeroutCounter : \(Utility.timerCounter)")
        if  Utility.timerCounter >= 10{
            Utility.resetTimer(false)
            Utility.hideProgressHUD()
            Utility.showToastMessage(kToast.General.RequestTimedOut)
            SocketIOManager.sharedInstance.reestablishConnection()
        }
    }
    
    //MARK:- Paging Methods
    static func initPagination(totalRecordsInPage:Int = 20) {
        self.totalRecordsInPage = totalRecordsInPage + 1
        pageTotal = 0
        pageCurrent = 1
    }
    
    static func countTotalPage(totalRecords : Int) {
        pageTotal = (totalRecords / totalRecordsInPage) + 1
    }
    
    static func movePageNext() {
        pageCurrent = (pageCurrent + 1 <= pageTotal) ? (pageCurrent + 1) : (pageTotal)
    }
    
    static func isPageNext() -> Bool {
        return pageCurrent < pageTotal
    }
    
    static func getPaginationDictionary() -> [String:Any] {
        return ["recordsPerPage":Utility.totalRecordsInPage - 1, "pageNumber":Utility.pageCurrent]
    }
    
    // MARK:- Validation Methods
    static func checkEmpty(_ candidate: String) -> Bool {
        return (candidate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "")
    }
    
    static func isValidRange(candidate:String, lowerLimit:Int,uperLimit:Int) -> Bool {
        let regexRange = "[[^a][a]]{\(lowerLimit),\(uperLimit)}"
        return NSPredicate(format: kRegex.SelfMatch, regexRange).evaluate(with: candidate)
    }
    
    static func isValidArtSize(_ candidate : String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.ArtSize).evaluate(with: candidate)
    }
    
    static func isValidArtValue(_ candidate : String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.ArtValue).evaluate(with: candidate)
    }
    
    static func isValidEmail(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.Email).evaluate(with: candidate)
    }
    
    static func isValidMobile(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.Mobile).evaluate(with: candidate)
    }
    
    static func isValidCreditCardNumber(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.Creditcard).evaluate(with: candidate)
    }
    
    static func isValidCvvNumber(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.Cvv).evaluate(with: candidate)
    }
    
    static func isValidExpiryYear(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.ExpiryYear).evaluate(with: candidate)
    }
    static func isValidExpiryMonth(_ candidate: String) -> Bool {
        return NSPredicate(format: kRegex.SelfMatch, kRegex.ExpiryMoth).evaluate(with: candidate)
    }
    
    static func isValidImageSize(_ pickedImage:UIImage, mb:Double, imageExtenstion:String) -> Bool {
        var imgData:Data?
        switch imageExtenstion {
        case "png":
            imgData = UIImagePNGRepresentation(pickedImage)
        case "jpg","jpeg":
            imgData = UIImageJPEGRepresentation(pickedImage, 1)
        default:
            break
        }
        
        if let imageData = imgData, (Double(imageData.count) / 1024.0) <= (mb * 1024.0){
            return true
        } else {
            Utility.showToastMessage("\(kToast.Validation.ImageSize)  \(Int(mb)) MB.")
            return false
        }
    }
    
    static func extractYoutubeIdFromLink(link: String) -> String? {
        guard let regExp = try? NSRegularExpression(pattern: kRegex.YoutubeIdLink, options: .caseInsensitive) else {
            return nil
        }
        let nsLink = link as NSString
        let options = NSRegularExpression.MatchingOptions(rawValue: 0)
        let range = NSRange(location: 0, length: nsLink.length)
        let matches = regExp.matches(in: link as String, options:options, range:range)
        if let firstMatch = matches.first {
            return nsLink.substring(with: firstMatch.range)
        }
        return nil
    }
    
    static func getVideoHtmlString(link:String, size:CGSize) -> String {
        let linkStr = self.extractYoutubeIdFromLink(link: link) ?? ""
        return "<body style=\"margin: 0; padding: 0;\"><iframe width=\"\(size.width)\" height=\"\(size.height)\" src=\"https://www.youtube.com/embed/\(linkStr)?rel=0&playsinline=1&showinfo=0\" allowfullscreen frameBorder=0  enablejsapi=\"1\" sandbox=\"allow-same-origin allow-pointer-lock allow-scripts allow-forms\" autoplay=\"0\" modestbranding=\"1\" ></iframe>"
    }
    
    static func isAllowToEdit(numOfTextFieldCharacters:Int, numOfwillTypeCharacter:Int, maxLimit:Int) -> Bool {
        let upperLimit = maxLimit - 1
        switch (numOfTextFieldCharacters, numOfwillTypeCharacter){
        case (0..<upperLimit, 0..<2), (0..<(upperLimit+2),0):
            return true
        case (upperLimit,1):
            return true
        default:
            return false
        }
    }
    
    static func convertJsonStringToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func checkCardTypeReturnImage(strCardType:String) -> UIImage {
        switch strCardType {
        case "Visa":
            return #imageLiteral(resourceName: "imgVisa")
        case "Discover":
            return #imageLiteral(resourceName: "imgDiscover")
        case "American Express":
            return #imageLiteral(resourceName: "imgAmericanExpress")
        case "JCB":
            return #imageLiteral(resourceName: "imgJcb")
        case "Maestro":
            return #imageLiteral(resourceName: "imgMaestro")
        case "MasterCard":
            return #imageLiteral(resourceName: "imgMasterCard")
        case "Cirrus":
            return #imageLiteral(resourceName: "imgCirrus")
        case "Diners Club":
            return #imageLiteral(resourceName: "imgDinersClub")
        default:
            return #imageLiteral(resourceName: "imgPlaceholder")
        }
    }
    
    // MARK:- Calulate Height Method
    static func heightForView(_ text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
    
    static func getLabelSize(_ strTitle : String, fontSize : CGFloat) -> CGSize {
        return strTitle.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)])
    }
    
    // MARK:- Alert Controller Method
    static func showAlert(_ controller : UIViewController, title : String, message : String , cancelButtonTitle:String? = nil, otherButtonTitle:String? = nil, anotherButtonTitle:String? = nil, alertStyle:UIAlertControllerStyle = .alert , tapCompletionBlock:UIAlertTapCompletionBlock? = nil) {
        alertViewController = UIAlertController(title: title, message: message, preferredStyle: alertStyle)
        var arrayTitles = [String]()
        if let cancelTitle = cancelButtonTitle{
            arrayTitles.append(cancelTitle)
            let cancelButton = UIAlertAction(title: cancelTitle, style: .cancel) { (action) in
                if let completionBlock = tapCompletionBlock{
                    completionBlock(alertViewController, arrayTitles.index(of: cancelTitle)!)
                } else {
                    alertViewController.dismiss(animated: true, completion: nil)
                }
            }
            alertViewController.addAction(cancelButton)
        }
        
        if let otherTitle = otherButtonTitle{
            arrayTitles.append(otherTitle)
            let otherButton = UIAlertAction(title: otherTitle, style: .default) { (action) in
                if let completionBlock = tapCompletionBlock{
                    completionBlock(alertViewController, arrayTitles.index(of: otherTitle)!)
                } else {
                    alertViewController.dismiss(animated: true, completion: nil)
                }
            }
            alertViewController.addAction(otherButton)
        }
        
        if let anotherTitle = anotherButtonTitle{
            arrayTitles.append(anotherTitle)
            let anotherButton = UIAlertAction(title: anotherTitle, style: .default) { (action) in
                if let completionBlock = tapCompletionBlock{
                    completionBlock(alertViewController, arrayTitles.index(of: anotherTitle)!)
                } else {
                    alertViewController.dismiss(animated: true, completion: nil)
                }
            }
            alertViewController.addAction(anotherButton)
        }
        
        // Default Alert
        if arrayTitles.count == 0{
            let anotherButton = UIAlertAction(title: kAlert.Button.OK, style: .cancel) { (action) in
                alertViewController.dismiss(animated: true, completion: nil)
            }
            alertViewController.addAction(anotherButton)
        }
        controller.present(alertViewController, animated: true, completion: nil)
    }
    
    // MARK:- Toast Method
    static func showToastMessage(_ message:String , yOffset:CGFloat = kGeneral.ToastYOffset, delay:TimeInterval = 2){
        guard let viewRoot = kGeneral.appDelegate.window?.rootViewController?.view else  { print("Error In Root View"); return }
        let hud = MBProgressHUD.showAdded(to: viewRoot, animated:true)
        hud.detailsLabel.text = message
        hud.mode = MBProgressHUDMode.text
        hud.offset.y = CGFloat(yOffset)
        hud.margin = 10
        hud.bezelView.color = UIColor.ProgressHud
        hud.detailsLabel.textColor = UIColor.white
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: delay)
    }
    
    // MARK:- MBProgressHUD Methods
    static func showProgressHUD(title:String = kToast.HudTitle.PleaseWait){
        hud = MBProgressHUD.showAdded(to:kGeneral.NavController.view, animated: true)
        hud?.bezelView.color = UIColor.ProgressHud
        hud?.mode = .indeterminate
        hud?.contentColor = UIColor.white
        hud?.label.numberOfLines = 0
        hud?.label.text = title
        hud?.isSquare = true
    }
    
    static func hideProgressHUD() -> Void{
        MBProgressHUD.hideAllHUDs(for: kGeneral.NavController.view, animated: true)
    }
    
    static func abbreviateNumber(_ number: NSNumber) -> String {
        // less than 1000, no abbreviation
        if Double(number) < 1000 {
            return "\(number)"
        }
        
        // less than 1 million, abbreviate to thousands
        if Double(number) < 1000000 {
            var n = Double(number);
            n = Double( floor(n/100)/10 )
            if (n == floor(n)){
                return "\(String(format:"%.f", n))K"
            } else {
                return "\(n.description)K"
            }
        }
        
        // more than 1 million, abbreviate to millions
        var n = Double(number)
        n = Double( floor(n/100000)/10 )
        if (n == floor(n)){
            return "\(String(format:"%.f", n))M"
        } else {
            return "\(n.description)M"
        }
    }
    
    static func convertFormatOfDate(_ date: String = "\(Date())", originalFormat: String = kString.MonthDayYearDateTime, destinationFormat: String) -> String {
        if Utility.checkEmpty(date) || Utility.checkEmpty(destinationFormat) || Utility.checkEmpty(destinationFormat) { return "N/A" }
        // Orginal format :
        let dateOriginalFormat = DateFormatter()
        dateOriginalFormat.dateFormat = originalFormat      // in the example it'll take "yy MM dd" (from our call)
        
        // Destination format :
        let dateDestinationFormat = DateFormatter()
        dateDestinationFormat.dateFormat = destinationFormat // in the example it'll take "EEEE dd MMMM yyyy" (from our call)
        
        // Convert current String Date to NSDate
        let dateFromString = dateOriginalFormat.date(from: date)
        
        // Convert new NSDate created above to String with the good format
        let dateFormated = dateDestinationFormat.string(from: dateFromString!)
        
        return dateFormated
    }
    
    // MARK:- set Root Method
    static func setupRootViewController(_ rootViewController:String = kViewController.Cover){
        guard let window =  kGeneral.appDelegate.window  else { print("Error in setup root."); return }
        if let token = UserDefaults.standard.value(forKey: kKeys.userAuthToken) as? String, let userDict = UserDefaults.standard.value(forKey:kKeys.user) as? String{
            STPPaymentConfiguration.shared().publishableKey = kSecret.StripPublicKey
            kStorage.objUser = User(dictionary: NSDictionary(dictionary: Utility.convertJsonStringToDictionary(text: userDict)!))
            kStorage.token = token
            kUrlApi.UserProfileImagePath = UserDefaults.standard.value(forKey: kKeys.userImagePath) as? String ?? ""
            //            kStorage.socialFollowers = UserDefaults.standard.value(forKey: kKeys.socialFollowers) as? Int ?? 0
            //            kStorage.referAmount = UserDefaults.standard.value(forKey: kKeys.referAmount) as? Int ?? 0
            self.fabricLogUser()
            if kGeneral.appDelegate.pusher != nil{
                kGeneral.appDelegate.pusher.nativePusher.subscribe(interestName: "buyer_\(kStorage.objUser.id)")
                //                Utility.showAlert(kGeneral.appDelegate.window!.rootViewController!, title: "", message: "buyer_\(kStorage.objUser.id)")
                if kStorage.objUser.isSeller{
                    print("seller_\(kStorage.objUser.id)")
                    kGeneral.appDelegate.pusher.nativePusher.subscribe(interestName: "seller_\(kStorage.objUser.id)")
                }
            }
        } else {
            kStorage.objUser = nil
            kStorage.token = ""
        }
        
        let rootView = kGeneral.StoryMain.instantiateViewController(withIdentifier: rootViewController)
        kGeneral.NavController.setViewControllers([rootView], animated: true)
        kGeneral.NavController.isNavigationBarHidden = true
        window.rootViewController = kGeneral.NavController
        window.makeKeyAndVisible()
    }
    
    static func checkUserLoginRetrunLoginViewVC() -> UIViewController? {
        if let _ = UserDefaults.standard.value(forKey: kKeys.userAuthToken) as? String, let _ = UserDefaults.standard.value(forKey:kKeys.user) as? NSDictionary{
            return nil
        }else{
            return kGeneral.StoryMain.instantiateViewController(withIdentifier: kViewController.Login) as! LoginViewController
        }
    }
    
    static func checkIsBuyerSeller(isSeller:Bool) {
        if !kStorage.objUser.isSeller{
            if isSeller{
                kGeneral.appDelegate.pusher.nativePusher.subscribe(interestName: "seller_\(kStorage.objUser.id)")
            }
            kStorage.objUser.isSeller = isSeller
            UserDefaults.standard.setValue(kStorage.objUser.toJsonString()
                , forKey: kKeys.user)
        }
    }
    
    static func getCountryListIfNeeded(isPaging:Bool = false, Callback callback: @escaping ()->()) {
        if !isPaging{ Utility.initPagination() }
        Utility.countTotalPage(totalRecords: Utility.countryTotalRecords)
        if kStorage.arrayCountries.count == 0 || isPaging{
            Base.payloadData = CountryPayLoadData()
            var params:[String:Any] = ["sortBy":"name","sortOrder":"desc"]
            params += Utility.getPaginationDictionary()
            CountryService.getCountryList(params: params) { (baseModel, error) in
                let countryPayload = baseModel.payload as! CountryPayLoadData
                kUrlApi.CountryFlagBaseUrl = countryPayload.basePath
                kStorage.arrayCountries = isPaging ? kStorage.arrayCountries + countryPayload.data : countryPayload.data
                callback()
            }
        } else {
            callback()
        }
    }
    
    static func callGetNotificationsIfNotificationScreenOnTop() -> Bool {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers.first as? UITabBarController, let tabBarChildNavController = tabBarController.selectedViewController as? UINavigationController, let _ = tabBarChildNavController.topViewController as? NotificationViewController{
            CustomDelegates.notificationDelegate?.getNotifications()
            return true
        } else {
            return false
        }
        
        //        if let objNotificationVC = UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController), let _ = objNotificationVC as? NotificationViewController{
        //            CustomDelegates.notificationDelegate?.getNotifications()
        //            return true
        //        } else {
        //            return false
        //        }
    }
    
    static func isLiveChatScreenOnTop() -> Bool {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers.first as? UITabBarController, let tabBarChildNavController = tabBarController.selectedViewController as? UINavigationController, let _ = tabBarChildNavController.topViewController as? LiveChatViewController{
            return true
        } else {
            return false
        }
        
        //        if let objLiveChatVC = UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController), let _ = objLiveChatVC as? LiveChatViewController{
        //            return true
        //        } else {
        //
        ////             ((UIApplication.shared.keyWindow!.rootViewController!.childViewControllers[0] as! UITabBarController).selectedViewController as! UINavigationController).topViewController!
        //            return false
        //        }
    }
    
    static func getMimeType(extenstion:String) -> String {
        switch extenstion {
        case "png":
            return enumMultipartDataMimeType.ImagePng.value
        case "jpg", "jpeg":
            return enumMultipartDataMimeType.ImageJpg.value
        default:
            print("Invalid Mime Type")
            return ""
        }
    }
    
    static func getImageOrFileName(type:enumImageOrFileType, extenstion:String) -> String {
        var imgPrefix = ""
        var timestamp = "\(Date().timeIntervalSinceNow)"
        switch type {
        case .Profile:
            imgPrefix = enumImageOrFileType.Profile.value
        case .Art:
            imgPrefix = enumImageOrFileType.Art.value
        case .Chat:
            imgPrefix = enumImageOrFileType.Chat.value
        case .IDImage:
            imgPrefix = enumImageOrFileType.IDImage.value
        case .AdobePhotoShopFile:
            imgPrefix = enumImageOrFileType.AdobePhotoShopFile.value
            timestamp = ""
        case .AdobeIllustratorFile:
            imgPrefix = enumImageOrFileType.AdobeIllustratorFile.value
            timestamp = ""
        }
        return "\(imgPrefix)\(timestamp).\(extenstion)"
    }
    
    static func registerPushNotification(isSound:Bool = true,isShowAlertMessage:Bool=false) {
        UNUserNotificationCenter.current().requestAuthorization(options: isSound ? [.alert, .badge, .sound] : [.alert, .badge]) { (granted, error) in
            guard error == nil else {
                //Display Error.. Handle Error.. etc..
                return
            }
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                //Handle user denying permissions..
                if isShowAlertMessage{
                    Utility.showAlert((kGeneral.appDelegate.window?.rootViewController)!, title: "", message: kAlert.Message.failRegisterNotificationMessgae)
                }
            }
        }
    }
    
    static func convertInDollars(_ value:String, isNeedCurrencySymbol:Bool=true, isNeedFractionDigits:Bool=true) -> String {
        let doubleValue = Double(value) ?? 0.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let dollerSymbol = isNeedCurrencySymbol ? "$" : ""
        if isNeedFractionDigits{
            formatter.minimumFractionDigits = value.contains(".00") ? 0 : 2
            formatter.maximumFractionDigits = 2
        }
        if let formattedString = formatter.string(from: NSNumber(value: doubleValue)){
            return "\(dollerSymbol)\(formattedString)"
        } else {
            return "\(dollerSymbol)0.00"
        }
    }
    
    // MARK:- Fabric Method
    static func fabricLogUser() {
        Crashlytics.sharedInstance().setUserEmail(kStorage.objUser.email)
        Crashlytics.sharedInstance().setUserName(kStorage.objUser.name)
    }
    
    // MARK:- Pusher Methods
    static func configurePusherNotification() {
        let options = PusherClientOptions(
            host: .cluster("us2")
        )
        kGeneral.appDelegate.pusher = Pusher(
            key: kSecret.PusherKey,
            options: options
        )
        kGeneral.appDelegate.pusher.delegate = kGeneral.appDelegate
    }
    
    // MARK:- Banner Image
    static func checkBannerImageFolderExist(strFolderName:String) {
        do {
            try FileManager.default.createDirectory(atPath: kGeneral.documentsDirectory.appendingPathComponent(strFolderName).path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }
    
    static func storeBannerImageIfNeeded(strFolderName:String,strImageName:String,imgType:String,imgPathStoreUrl:URL?,Callback callback: (() -> Void)? = nil) {
        let isAnimatedImage = strFolderName == enumBackGroundType.SplashAnimatedBanner.value
        if isAnimatedImage {Utility.showProgressHUD()}
        if let storedImageUrl = imgPathStoreUrl?.lastPathComponent, storedImageUrl != strImageName{
            if let percentUrl = (kUrlApi.BannerImagePath+strImageName).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: percentUrl) {
                DispatchQueue.global().async {
                    var imageData:NSData!
                    if let data = try? Data(contentsOf: url) {
                        imageData = NSData.init(data: data)
                    }
                    let fullImagePath = kGeneral.documentsDirectory.appendingPathComponent(strFolderName).appendingPathComponent(strImageName)
                    if imageData != nil{
                        DispatchQueue.main.async {
                            let strFullImagePath = fullImagePath.path.replacingOccurrences(of: " ", with: "")
                            let _ = imageData.write(toFile: strFullImagePath, atomically: true)
                            UserDefaults.standard.set(strFullImagePath, forKey: imgType)
                            UserDefaults.standard.synchronize()
                            print("Store \(strImageName) Image!!!")
                            if isAnimatedImage{
                                Utility.hideProgressHUD()
                                callback!()
                            }
                        }
                    }
                }
            }else{
                print("url not valid")
            }
        }else{
            if isAnimatedImage{
                Utility.hideProgressHUD()
            }
            print("\(imgType) image already stored")
        }
    }
    
    
    
//    static func storeBannerAnimatedImageIfNeeded(strFolderName:String,strImageName:String,imgType:String,imgPathStoreUrl:URL?,Callback callback: @escaping ()->()) {
//        if let storedImageUrl = imgPathStoreUrl?.lastPathComponent, storedImageUrl != strImageName{
//            
//            let strUrl = strFolderName == enumBackGroundType.SplashAnimatedBanner.value ? "http://www.gifbin.com/bin/4802swswsw04.gif":(kUrlApi.BannerImagePath+strImageName)
//            if let percentUrl = strUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: percentUrl) {
//                DispatchQueue.global().async {
//                    var imageData:NSData!
//                    if let data = try? Data(contentsOf: url) {
//                        imageData = NSData.init(data: data)
//                    }
//                    let fullImagePath = kGeneral.documentsDirectory.appendingPathComponent(strFolderName).appendingPathComponent(strImageName)
//                    if imageData != nil{
//                        DispatchQueue.main.async {
//                            let strFullImagePath = fullImagePath.path.replacingOccurrences(of: " ", with: "")
//                            let _ = imageData.write(toFile: strFullImagePath, atomically: true)
//                            UserDefaults.standard.set(strFullImagePath, forKey: imgType)
//                            UserDefaults.standard.synchronize()
//                            print("Store \(strImageName) Image!!!")
//                            callback()
//                        }
//                    }
//                }
//            }else{
//                print("url not valid")
//            }
//        }else{
//            print("\(imgType) image already stored")
//            callback()
//        }
//    }
//
    
    
    
    // MARK:- User Data Clear & Set Default Data Methods
    static func clearUserDefaultData(){
        UserDefaults.standard.set(nil, forKey: kKeys.user)
        UserDefaults.standard.setValue(nil, forKey: kKeys.userAuthToken)
        UserDefaults.standard.setValue(0, forKey: kKeys.socialFollowers)
        UserDefaults.standard.setValue(0, forKey: kKeys.referAmount)
        UserDefaults.standard.setValue(nil, forKey: kKeys.userImagePath)
        
        UserDefaults.standard.synchronize()
        kStorage.objUser = nil
        kStorage.token = ""
        kStorage.isBuyer = true
        UIApplication.shared.applicationIconBadgeNumber = 0
        if kStorage.objUser != nil{
            kGeneral.appDelegate.pusher.nativePusher.unsubscribe(interestName: kStorage.objUser.id)
            kGeneral.appDelegate.pusher.nativePusher.unsubscribe(interestName: "buyer_\(kStorage.objUser.id)")
            kGeneral.appDelegate.pusher.nativePusher.unsubscribe(interestName: "seller_\(kStorage.objUser.id)")
        }
        UIApplication.shared.unregisterForRemoteNotifications()
        InstagramLoginManager.logout()
    }
    
    static func getError(domain:String = "CustomError", code:Int = 0, message:String = "") -> Error {
        let objError:Error = NSError(domain: "CustomError", code: code, userInfo: ["error":message])
        return objError
    }
    
    static func navigateOnNotification(notification:NSDictionary) {
        if Utility.checkAndStoreUserCredential(){
            if let aps = notification["aps"] as? NSDictionary {
                if let categoryType =  aps["category"] as? String,categoryType == kString.Order || categoryType == kString.Payout{
                    print(categoryType)
                    UIApplication.shared.applicationIconBadgeNumber = max(0,UIApplication.shared.applicationIconBadgeNumber - 1)
                    if let info = aps["data"] as? NSDictionary{
                        if let user = info["user"] as? String ,user == kString.Buyer{
                            print(user)
                            kStorage.isBuyer = true
                        }else if let user = info["user"] as? String ,user == kString.Seller{
                            print(user)
                            kStorage.isBuyer = false
                        }
                        if !Utility.callGetNotificationsIfNotificationScreenOnTop(){
                            kStorage.enumRootDestination = .Notification
                            Utility.setupRootViewController(kViewController.RootTabBarController)
                        }else{
                            // notification on top controller
                            CustomDelegates.notificationDelegate?.getNotifications()
                        }
                    }
                    Utility.closeLiveChatImmediate()
                }else if let categoryType =  aps["category"] as? String,categoryType == kString.Chat{
                    kStorage.isBuyer = true
                    kStorage.isChatLive = false
                    
                    if Utility.isLiveChatScreenOnTop(){
                        if let objSocketEngine = SocketIOManager.sharedInstance.socket.engine, objSocketEngine.connected {
                            SocketIOManager.sharedInstance.closeConnection()
                            perform(#selector(self.startConnectionIfInternetOn), with: nil, afterDelay: 0.1)
                            return
                        } else {
                            self.startConnectionIfInternetOn()
                        }
                    } else {
                        kStorage.enumRootDestination = .LiveChat
                        Utility.setupRootViewController(kViewController.RootTabBarController)
                    }
                }
            }
        }
    }
    
    static func presentDismissSplashScreen(isPresent:Bool, callback: @escaping () -> () = { _ in }) {
        if let rootController = kGeneral.appDelegate.window?.rootViewController{
            if isPresent{
                let destView = kGeneral.StoryMain.instantiateViewController(withIdentifier: kViewController.Splash)
                rootController.present(destView, animated: false, completion: {
                    callback()
                })
            } else {
                rootController.dismiss(animated: false, completion: {
                    callback()
                })
            }
        }
    }
    
    static func startConnectionIfInternetOn() {
        if Reachability.isInternetAvailable() {
            Utility.showProgressHUD()
            SocketIOManager.sharedInstance.addBasicHandlers()
            SocketIOManager.sharedInstance.establishConnection()
        } else {
            Utility.showToastMessage(kToast.General.CheckInternetConnection)
        }
    }
    
    static func getMaxBirthDate(maxYear:Int=5) -> Date {
        if let maxDate = Calendar.current.date(byAdding: .year, value: -maxYear, to: Date()){
            return maxDate
        } else {
            return Date()
        }
    }
    
    static func navigateOnSettingPermission() {
        if let settingUrl = URL(string: UIApplicationOpenSettingsURLString){
            UIApplication.shared.open(settingUrl)
        }
    }
    
    static func checkCameraPermission(callback: @escaping ()->()) {
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch authStatus {
        case .authorized:
            callback()
        case .denied:
            Utility.navigateOnSettingPermission()
        case .restricted:
            Utility.showToastMessage(kToast.General.CameraRestricted)
        case .notDetermined:
            // ask for permissions
            if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 0 {
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                    DispatchQueue.main.async() {
                        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
                        switch authStatus {
                        case .authorized:
                            callback()
                        case .denied:
                            Utility.navigateOnSettingPermission()
                        case .restricted:
                            Utility.showToastMessage(kToast.General.CameraRestricted)
                        case .notDetermined:
                            // won't happen but still
                            print("Not Determined")
                        }
                    }
                }
            }
        }
    }
    
    static func checkPhotoLibraryPermission(callback: @escaping ()->()) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            callback()
        case .denied:
            Utility.navigateOnSettingPermission()
        case .restricted:
            Utility.showToastMessage(kToast.General.PhotoRestricted)
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized:
                    callback()
                case .denied:
                    Utility.navigateOnSettingPermission()
                case .restricted:
                    Utility.showToastMessage(kToast.General.PhotoRestricted)
                case .notDetermined:
                    // won't happen but still
                    print("Not Determined")
                }
            }
        }
    }
    
    static func checkAndStoreUserCredential() -> Bool {
        if let token = UserDefaults.standard.value(forKey: kKeys.userAuthToken) as? String, let userDict =
            UserDefaults.standard.value(forKey:kKeys.user) as? String{
            kStorage.token = token
            kStorage.objUser = User(dictionary: NSDictionary(dictionary: Utility.convertJsonStringToDictionary(text: userDict)!))
            return true
        } else {
            return false
        }
    }
    
    static func closeLiveChatImmediate() {
        SocketIOManager.sharedInstance.closeConnection()
        SocketIOManager.sharedInstance.socket.removeAllHandlers()
        kStorage.isChatLive = false
        Utility.resetTimer(false)
        CustomDelegates.liveChatDelegate?.closeLiveChat()
    }
    
    static func clearBedgeCountIfAppLaunchedFirstTime() {
        guard let _ = UserDefaults.standard.value(forKey: kKeys.isAppAlreadyLaunched) as? Bool else {
            UIApplication.shared.applicationIconBadgeNumber = 0
            UserDefaults.standard.set(true, forKey: kKeys.isAppAlreadyLaunched)
            return
        }
    }
}
