//
//  ViewController.swift
//  LLLLable
//
//  Created by Qiang Ma 马强 on 2018/10/18.
//  Copyright © 2018 Arror. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: PlaceholderTextView! {
        didSet {
            self.textView.textContainer.maximumNumberOfLines = 1
            self.textView.textContainerInset = .zero
            self.textView.textContainer.lineFragmentPadding = 0.0
            self.textView.isEditable = false
            self.textView.isSelectable = false
            self.textView.isScrollEnabled = false
            self.textView.isUserInteractionEnabled = false
            self.textView.placeholerText = "回复：夏皮皮"
            self.textView.placeholderTextColor = .lightGray
            self.textView.text = ""
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func inputButtonTapped(_ sender: UIBarButtonItem) {
        let vc = InputViewController.makeViewController()
        self.present(vc, animated: false, completion: nil)
    }
}


//MARK: InputeViewController

public final class InputViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    private let textViewBottomAndTopCon:CGFloat = 15.0;
    @IBOutlet weak var countLabelHightConstraints: NSLayoutConstraint!
    private var placeholder: String? = nil
    private var initialContent: String? = nil

    @IBOutlet weak var heightConstraints: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var inputBar: InputBar! {
        didSet {
            self.inputBar.delegate = self
        }
    }
    
    @IBOutlet weak var dimmingView: UIView! {
        didSet {
            self.dimmingView.alpha = 0.0
            self.dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
        }
    }
    
    private var observer: NSKeyValueObservation? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.heightConstraints.constant = 50.0
//        self.inputBar.textView.placeholder = self.placeholder
        self.inputBar.textView.text = self.initialContent
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            guard
                let c = change,
                let value = c[.newKey] as? NSValue else {
                    return
            }
            
            let height = max(min(value.cgSizeValue.height + textViewBottomAndTopCon * 2 + self.countLabelHightConstraints.constant, 132.0), 50.0)
            self.updateInputBarHeight(height)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateInputBarHeight(_ height: CGFloat, animated: Bool = true) {
        self.heightConstraints.constant = height
        if animated {
            self.view.setNeedsLayout()
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
        self.hiddenInputBar {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    private var keyboardFrameObserver: NSObjectProtocol? = nil
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addObservers()
        self.showInputBar {}
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeObservers()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return UIPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension InputViewController {
    
    private func addObservers() {
        
        self.keyboardFrameObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard
                let strongSelf = self,
                let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return
            }
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.5
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
            let localFrame = strongSelf.view.convert(keyboardFrame, from: UIScreen.main.coordinateSpace)
            let safeAreaInsetsBottom: CGFloat = {
                if #available(iOS 11.0, *) {
                    return strongSelf.view.safeAreaInsets.bottom
                } else {
                    return 0
                }
            }()
            if localFrame.minY.isLess(than: strongSelf.view.bounds.maxY - 1.0) {
                strongSelf.bottomConstraints.constant = strongSelf.view.bounds.maxY - localFrame.minY - safeAreaInsetsBottom
            } else {
                strongSelf.bottomConstraints.constant = 0.0
            }
            strongSelf.view.setNeedsLayout()
            UIView.beginAnimations("Animation", context: nil)
            UIView.setAnimationDuration(duration)
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: curve) ?? .easeInOut)
            strongSelf.view.layoutIfNeeded()
            UIView.commitAnimations()
        })
        self.inputBar.textView.addObserver(self, forKeyPath: "contentSize", options: [.initial, .new], context: nil)
    }
    
    private func removeObservers() {
        if let observer = self.keyboardFrameObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.inputBar.textView.removeObserver(self, forKeyPath: "contentSize")
    }
}

extension InputViewController: InputBarDelegate {
    
    private func showInputBar(withCompletion completion: @escaping () -> Void) {
        self.inputBar.textView.becomeFirstResponder()
        UIView.animate(withDuration: 0.5, animations: {
            self.dimmingView.alpha = 0.3
        }, completion: { _ in
            completion()
        })
    }
    
    private func hiddenInputBar(withCompletion completion: @escaping () -> Void) {
        self.inputBar.textView.resignFirstResponder()
        self.inputBar.textView.setContentOffset(.zero, animated: false)
        self.heightConstraints.constant = 50.0
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.5, animations: {
            self.dimmingView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }
    
    func keyboardSendButtonTapped(_ bar: InputBar) {
        
    }
    
    func textDidChanged(_ bar: InputBar, text: String) {
        let count = text.utf16.count
        switch count {
        case 51...:
            if bar.textCountLabel.isHidden {
                self.countLabelHightConstraints.constant = 20.0
                let height = max(min(self.inputBar.textView.contentSize.height + 50.0, 132.0), 50.0)
                self.updateInputBarHeight(height)
            }
            
            bar.textCountLabel.isHidden = false
            bar.textCountLabel.text = "\(50 - count)"
            bar.textCountLabel.textColor = .red
           
            
        case 30...50:
            if bar.textCountLabel.isHidden {
                self.countLabelHightConstraints.constant = 20.0
                let height = max(min(self.inputBar.textView.contentSize.height + 50.0, 132.0), 50.0)
                self.updateInputBarHeight(height)
            }
            
            bar.textCountLabel.isHidden = false
            bar.textCountLabel.text = "\(50 - count)"
            bar.textCountLabel.textColor = .lightGray

        default:
            
            if bar.textCountLabel.isHidden == false {
                self.countLabelHightConstraints.constant = 0.0
                let height = max(min(self.inputBar.textView.contentSize.height + 30.0, 132.0), 50.0)
                self.updateInputBarHeight(height)
                
            }
            bar.textCountLabel.isHidden = true
            
        }
    }
}

extension InputViewController {
    
    static func makeViewController(placeholder: String? = nil, initialContent: String? = nil) -> InputViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InputViewController") as! InputViewController
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        vc.placeholder = placeholder
        vc.initialContent = initialContent
        return vc
    }
    
    static func inputeViewController(configure:InputViewConfigure ,appearence:InputViewAppreaence) -> InputViewController {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InputViewController") as! InputViewController
        
        return vc;
    }
}

protocol InputBarDelegate: class {
    
    func keyboardSendButtonTapped(_ bar: InputBar)
    func textDidChanged(_ bar: InputBar, text: String)
}


// MARK: - TODO

class InputViewConfigure: NSObject {
    
    var maxWords : Int?
    var placeholder : String?
    var initialContent : String?
    var InputViewHight: CGFloat?
}

class InputViewAppreaence: NSObject {
    
    var countLabelWarnTextColor : UIColor?
    var countLabelErrorTextColor : UIColor?
    var countLabelFont : UIFont?
    var inputBarBackgroudColor:UIColor?
}

// MARK: InputViewAppearence

class InputBar: SafeAreaCompatibleView, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView! {
        didSet {
            self.textView.delegate = self
            self.textView.textContainerInset = .zero
            self.textView.textContainer.lineFragmentPadding = 0.0
        }
    }
    @IBOutlet weak var textCountLabel: UILabel!
    
    weak var delegate: InputBarDelegate? = nil
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.delegate?.keyboardSendButtonTapped(self)
            return false
        } else {
            return true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard textView.markedTextRange == nil else { return }
        self.delegate?.textDidChanged(self, text: textView.text)
    }
}


public final class InputComponentController {
    
    public enum Behaviour {
        case abandon
        case collect
    }
    
    private weak var viewController: UIViewController?
    
    public init(from viewController: UIViewController) {
        self.viewController = viewController
    }
    
    private var _block: (Behaviour, String) -> Void = { _, _  in }
    
    public func showInputComponent(placeholder: String? = nil, initialContent: String? = nil, completion: @escaping (Behaviour, String) -> Void) {
        guard
            let host = self.viewController else {
                return
        }
        let vc = InputViewController.makeViewController(placeholder: placeholder, initialContent: initialContent)
        self._block = completion
        host.present(vc, animated: false, completion: nil)
    }
}

func test() {
    
    let controller = InputComponentController(from: UIViewController.init())
    
    controller.showInputComponent(placeholder: nil, initialContent: nil) { behaviout, content in
        switch behaviout {
        case .abandon:
            print(content)
        case .collect:
            print(content)
        }
    }
}


//MARK: Placeholder

class PlaceholderTextView: UITextView {
    
//    override func becomeFirstResponder() -> Bool {
//        let willBecomeFirstResponder = super.becomeFirstResponder()
//        return willBecomeFirstResponder
//    }
//
//    override func resignFirstResponder() -> Bool {
//        let willResignFirstResponder = super.resignFirstResponder()
//        return willResignFirstResponder
//    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private var textChangedObserver: NSObjectProtocol? = nil
    
    private func commonInit() {
        self.textChangedObserver = NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: nil, queue: .main) { [weak self] n in
            guard
                let textView = n.object as? PlaceholderTextView, textView == self else {
                    return
            }
            textView.setNeedsDisplay()
        }
    }
    
    deinit {
        if let observer = self.textChangedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var placeholerText: String? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var placeholderTextColor: UIColor? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if !self.hasText, let placeholer = self.placeholerText, !placeholer.isEmpty {
            let rect = CGRect(
                x: self.textContainerInset.left + self.textContainer.lineFragmentPadding,
                y: self.textContainerInset.top,
                width: self.bounds.width - self.textContainerInset.left - self.textContainerInset.right - self.textContainer.lineFragmentPadding * 2.0,
                height: self.bounds.height - self.textContainerInset.top - self.textContainerInset.bottom
            )
            let attrbutes: [NSAttributedString.Key: Any] = {
                var dict: [NSAttributedString.Key: Any] = [:]
                dict[.foregroundColor] = self.placeholderTextColor
                dict[.font] = self.font
                return dict
            }()
            (placeholer as NSString).draw(in: rect, withAttributes: attrbutes)
        }
    }
}
