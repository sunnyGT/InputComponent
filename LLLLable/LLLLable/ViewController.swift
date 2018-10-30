//
//  ViewController.swift
//  LLLLable
//
//  Created by Qiang Ma 马强 on 2018/10/18.
//  Copyright © 2018 Arror. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func inputButtonTapped(_ sender: UIBarButtonItem) {
        let vc = InputViewController.makeViewController()
        self.present(vc, animated: false, completion: nil)
    }
}

public final class InputViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var bar: SafeAreaCompatibleView!
    
    @IBOutlet weak var dimmingView: UIView! {
        didSet {
            self.dimmingView.alpha = 0.0
            self.dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
        self.textView.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
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
            if localFrame.minY >= strongSelf.view.bounds.maxY {
                strongSelf.bottomConstraints.constant = strongSelf.view.bounds.maxY - localFrame.minY
            } else {
                strongSelf.bottomConstraints.constant = strongSelf.view.bounds.maxY - localFrame.minY - safeAreaInsetsBottom
            }
            strongSelf.view.setNeedsLayout()
            strongSelf.bar.setNeedsLayout()
            strongSelf.bar.layoutIfNeeded()
            UIView.beginAnimations("Animation", context: nil)
            UIView.setAnimationDuration(duration)
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: curve) ?? .easeInOut)
            strongSelf.view.layoutIfNeeded()
            UIView.commitAnimations()
        })
        self.textView.becomeFirstResponder()
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
