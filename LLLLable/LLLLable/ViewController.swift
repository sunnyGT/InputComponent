//
//  ViewController.swift
//  LLLLable
//
//  Created by Qiang Ma 马强 on 2018/10/18.
//  Copyright © 2018 Arror. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView! {
        didSet {
            self.textView.textContainer.maximumNumberOfLines = 1
            self.textView.textContainerInset = .zero
            self.textView.textContainer.lineFragmentPadding = 0.0
            self.textView.isEditable = false
            self.textView.isSelectable = false
            self.textView.isScrollEnabled = false
            self.textView.isUserInteractionEnabled = false
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

public final class InputViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var heightConstraints: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var inputBar: InputBar!
    
    @IBOutlet weak var dimmingView: UIView! {
        didSet {
            self.dimmingView.alpha = 0.0
            self.dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
        }
    }
    
    private var observer: NSKeyValueObservation? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.inputBar.textView.addObserver(self, forKeyPath: "contentSize", options: [.initial, .old, .new], context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            guard
                let c = change,
                let value = c[.newKey] as? NSValue else {
                    return
            }
            let height = max(min(value.cgSizeValue.height + 30.0, 132.0), 50.0)
            self.updateInputBarHeight(height)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        self.inputBar.textView.removeObserver(self, forKeyPath: "contentSize")
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
        self.inputBar.textView.resignFirstResponder()
        UIView.animate(withDuration: 0.5, animations: {
            self.dimmingView.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private var keyboardFrameObserver: NSObjectProtocol? = nil
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        self.inputBar.textView.becomeFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0.3
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let observer = self.keyboardFrameObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return UIPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension InputViewController {
    
    static func makeViewController() -> InputViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InputViewController") as! InputViewController
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        return vc
    }
}

class InputBar: SafeAreaCompatibleView {
    
    @IBOutlet weak var textView: UITextView! {
        didSet {
            self.textView.textContainerInset = .zero
            self.textView.textContainer.lineFragmentPadding = 0.0
        }
    }
}
