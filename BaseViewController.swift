import UIKit

class BaseViewController: UIViewController {
    // MARK: - Variables
    var textFieldActive : UITextField!
    var textViewActive : UITextView!
    let networkManager = NetworkManager.sharedInstance()
    var dateToolbar:UIToolbar!
    var datePickerView = UIDatePicker()
    var selectedDate = String()
    let dateFormatter = DateFormatter()
    let dateFormatterGet = DateFormatter()
    var imagePicker = UIImagePickerController()
    var viewPlaceholder = UIView()
    
    // MARK: - UIView Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    // MARK: - Navigation Bar & Navigation Methods
    func configureNavBar(title:String = "", isBackHidden:Bool = false, isCancelIcon:Bool = false, rightTitleOrImage:Any? = nil , animated:Bool = true, commonColor:UIColor = .Theme, leftButtonColor:UIColor? = nil, titleColor:UIColor? = nil, rightButtonColor:UIColor? = nil) {
        
        let colorLeftButton = leftButtonColor == nil ? commonColor : leftButtonColor!
        let colorRightButton = rightButtonColor == nil ? commonColor : rightButtonColor!
        let colorTitle = titleColor == nil ? commonColor : titleColor!
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = UIColor.clear

        if self.tabBarController != nil{
            self.navigationItem.title = title
        } else {
            self.title = title
        }

        if !isBackHidden{
            let viewBackContainer:UIView = UIView()
            viewBackContainer.backgroundColor = UIColor.clear
            viewBackContainer.frame = CGRect(x: 0, y: 0, width: 60, height: 45)
            let backButton:UIButton = UIButton()
            let originalImage = #imageLiteral(resourceName: "back100")
            let templateImage = originalImage.withRenderingMode(.alwaysTemplate)
            backButton.setImage(isCancelIcon ? #imageLiteral(resourceName: "imgCancel") : templateImage, for: UIControlState.normal)
            backButton.imageView?.tintColor = colorLeftButton
            backButton.frame =  CGRect(x: 0, y: 1, width: 60, height: 44)
            let cancelImageInsets = UIEdgeInsets(top: 19, left: 16, bottom:10, right: 28)
            let backImageInsets = UIEdgeInsets(top: 15, left: 18, bottom:6, right: 28)
            backButton.imageEdgeInsets = isCancelIcon ? cancelImageInsets : backImageInsets
            backButton.contentMode = UIViewContentMode.center
            backButton.addTarget(self, action: #selector(self.navigateBack), for: .touchUpInside)
            viewBackContainer.addSubview(backButton)
            viewBackContainer.transform = CGAffineTransform(translationX: -1, y: 0)
            let leftBarButton = UIBarButtonItem(customView: viewBackContainer)
            self.navigationItem.leftBarButtonItem = leftBarButton
            self.navigationItem.leftBarButtonItem?.tintColor = colorLeftButton
            self.navigationItem.setHidesBackButton(false, animated: true)
        } else {
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
        
        if rightTitleOrImage != nil {
            if let titleRight = rightTitleOrImage as? String{
                let rightBarButtonItem = UIBarButtonItem(title: titleRight, style: .plain, target: self, action: #selector(self.clickRightBarButtonItem))
                self.navigationItem.rightBarButtonItem = rightBarButtonItem
                let titleTextAttributes:[String:Any] = [NSFontAttributeName : UIFont.init(name: kFonts.AvenirMedium, size: 16)!]
                self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(titleTextAttributes, for: .normal)
                self.navigationItem.rightBarButtonItem?.tintColor = colorRightButton
            } else if let imageRight = rightTitleOrImage as? UIImage{
                let rightBarButtonItem = UIBarButtonItem(image: imageRight, style: .plain, target: self, action: #selector(self.clickRightBarButtonItem))
                self.navigationItem.rightBarButtonItem = rightBarButtonItem
                self.navigationItem.rightBarButtonItem?.tintColor = colorRightButton
                self.navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsets(top: 5, left: 3, bottom: 2, right: 3)
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        //Set Title Attributes
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : colorTitle,
            NSFontAttributeName : UIFont.init(name: kFonts.AvenirBook, size: 20)!
        ]
        self.navigationController?.navigationBar.setTitleVerticalPositionAdjustment(4, for: .default)
        
        //Remove Bottom Border/Shadow & Hide/Show
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.fromColor(color: .clear), for: UIBarMetrics.default)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func navigateBack() {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    func clickRightBarButtonItem() {}
    
    func navigate(_ destViewController : String,storyBoard:UIStoryboard) {
        self.navigationController?.pushViewController(storyBoard.instantiateViewController(withIdentifier: destViewController), animated: true)
    }
    
    // MARK: - Placeholder View Method
    func setPlaceholderIfNeeded(arrayCount:Int = 1, top:CGFloat = 0, bottom:CGFloat = 0, backColor:UIColor = UIColor.white, textColor:UIColor = UIColor.lightGray, strAlertTitle:String, isTryAgain:Bool = false) {
        //        let placeholderY:CGFloat = ((top != 64 && top != 0) || self.tabBarController != nil) ? top : 0
        let placeholderY:CGFloat = top
        let placeholderHeight = view.frame.size.height - top - bottom
        viewPlaceholder.frame = CGRect(x: 0, y: placeholderY, width: view.frame.size.width, height: placeholderHeight)
        if top != 64, top != 0{
            viewPlaceholder.frame.origin.y = top
        }
        viewPlaceholder.backgroundColor = backColor
        if arrayCount == 0{
            if let currentViewController = self.navigationController?.topViewController{
                if currentViewController.view.subviews.contains(self.viewPlaceholder){
                    self.viewPlaceholder.subviews.forEach({ (subview) in
                        subview.removeFromSuperview()
                    })
                    self.viewPlaceholder.removeFromSuperview()
                }
                if !currentViewController.view.subviews.contains(self.viewPlaceholder){
                    let label = UILabel(frame: CGRect(x: 20, y: 0, width: viewPlaceholder.frame.size.width - 40, height: viewPlaceholder.frame.size.height))
                    label.text = strAlertTitle
                    label.textColor = textColor
                    label.textAlignment = .center
                    label.numberOfLines = 0
                    label.font = UIFont(name: kFonts.AvenirMedium, size: 17)
                    viewPlaceholder.addSubview(label)
                    
                    if isTryAgain{
                        let buttonTryAgain = UIButton(type: .custom)
                        let buttonWidth:CGFloat = 100
                        let buttonX:CGFloat = (kGeneral.ScreenSize.width / 2) - (buttonWidth / 2)
                        let buttonY:CGFloat = (placeholderHeight / 2) + 100
                        
                        buttonTryAgain.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: 40)
                        buttonTryAgain.addTarget(self, action: #selector(self.buttonTryAgainClicked(_:)), for: .touchUpInside)
                        buttonTryAgain.setTitle(kAlert.Button.TryAgain, for: .normal)
                        buttonTryAgain.setTitleColor(UIColor.lightGray, for: .normal)
                        buttonTryAgain.layer.borderWidth = 1
                        buttonTryAgain.tag = 201
                        buttonTryAgain.layer.borderColor = UIColor.lightGray.cgColor
                        buttonTryAgain.titleLabel?.font = UIFont(name: kFonts.AvenirMedium, size: 17)
                        viewPlaceholder.addSubview(buttonTryAgain)
                    }
                    
                    currentViewController.view.addSubview(self.viewPlaceholder)
                }
            }
            self.viewPlaceholder.isHidden = false
        } else {
            self.viewPlaceholder.isHidden = true
        }
    }
    
    func buttonTryAgainClicked(_ sender:UIButton) {}
    
    func initDatePicker(maximumDate:Date = Date())  {
        dateFormatter.dateFormat = kString.yyyy_MM_dd
        dateFormatterGet.dateFormat = kString.MonthDayYear
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.backgroundColor = UIColor.white
        //yyyy-MM-dd
        var dateComponents = Calendar.current.dateComponents([.year], from: Date())
        if let currentYear = dateComponents.year{
            dateComponents.year = currentYear - 90
            if let minimumDate = dateFormatter.date(from: "\(dateComponents.year!)-01-01"){
                datePickerView.minimumDate = minimumDate
            }
        }
        datePickerView.maximumDate = maximumDate
        datePickerView.addTarget(self, action: #selector(self.handleDatePicker(_:)), for: UIControlEvents.valueChanged)

    }
    
    func handleDatePicker(_ sender: UIDatePicker) {
        selectedDate = dateFormatter.string(from: sender.date)
    }
    
    func cancelDatePicker() {
        textFieldActive.resignFirstResponder()
        selectedDate = ""
    }
    
    func doneWithDatePicker() {
        if selectedDate != "", let dateSystem = dateFormatter.date(from: selectedDate){
            textFieldActive.text = dateFormatterGet.string(from: dateSystem)
        }
        textFieldActive.resignFirstResponder()
    }
    
    // MARK: - UIToolbar Methods
    func addDoneToolbar(isDatePicker:Bool = false, backColor:UIColor = UIColor.Theme, textColor:UIColor = UIColor.white)  {
        dateToolbar = UIToolbar(frame: CGRect(x:0, y:0, width:self.view.frame.size.width, height:kGeneral.DoneToolBarHeight))
        dateToolbar.barStyle = UIBarStyle.default
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: textColor]
        if isDatePicker{
            textFieldActive.inputView = datePickerView
            selectedDate = dateFormatter.string(from: datePickerView.date)
            dateToolbar.items = [
                UIBarButtonItem(title: kAlert.Button.Cancel, style: UIBarButtonItemStyle.plain, target: self, action:#selector(self.cancelDatePicker)),
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: kAlert.Button.Done, style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.doneWithDatePicker))]
            dateToolbar.items?[0].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
            dateToolbar.items?[2].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
        }else{
            dateToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: kAlert.Button.Done, style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.doneWithToolbar))]
            dateToolbar.items?[1].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
        }
        dateToolbar.sizeToFit()
        dateToolbar.barTintColor = backColor
        dateToolbar.items?[1].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
        textFieldActive.inputAccessoryView = dateToolbar
    }
    
    func doneWithToolbar() {
        textFieldActive.resignFirstResponder()
    }
    
    func addDoneToolbarToTextView(backColor:UIColor = UIColor.Theme, textColor:UIColor = UIColor.white)  {
        dateToolbar = UIToolbar(frame: CGRect(x:0, y:0, width:self.view.frame.size.width, height:kGeneral.DoneToolBarHeight))
        dateToolbar.barStyle = UIBarStyle.default
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: textColor]
        dateToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: kAlert.Button.Done, style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.doneWithToolbarTextView))]
        dateToolbar.items?[1].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
        dateToolbar.sizeToFit()
        dateToolbar.barTintColor = backColor
        dateToolbar.items?[1].setTitleTextAttributes(titleDict as? [String : Any], for: .normal)
        textViewActive.inputAccessoryView = dateToolbar
    }
    
    func doneWithToolbarTextView() {
        textViewActive.resignFirstResponder()
    }
    
}
