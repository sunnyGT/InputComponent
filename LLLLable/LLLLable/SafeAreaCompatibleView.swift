//
//  SafeAreaCompatibleView.swift
//  LLLLable
//
//  Created by Qiang Ma 马强 on 2018/10/29.
//  Copyright © 2018 Arror. All rights reserved.
//

import UIKit

open class SafeAreaCompatibleView: UIView {
    
    private let backgroundView = UIView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commentInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commentInit()
    }
    
    open override var backgroundColor: UIColor? {
        set {
            self.backgroundView.backgroundColor = newValue
            super.backgroundColor = newValue
        }
        get {
            return super.backgroundColor
        }
    }
    
    private var top: NSLayoutConstraint? = nil
    private var bottom: NSLayoutConstraint? = nil
    private var left: NSLayoutConstraint? = nil
    private var right: NSLayoutConstraint? = nil
    
    func commentInit() {
        self.insertSubview(self.backgroundView, at: 0)
        self.backgroundView.backgroundColor = UIColor.cyan
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.top = self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        self.bottom = self.backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        self.left = self.backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor)
        self.right = self.backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor)
        self.addConstraints([self.top, self.bottom, self.left, self.right].compactMap { $0 })
        self.backgroundView.backgroundColor = self.backgroundColor
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else { return }
        let superviewBounds = superview.bounds
        var superviewSafeAreaInsets = UIEdgeInsets.zero
        if #available(iOS 11, *){
            
             superviewSafeAreaInsets = superview.safeAreaInsets
        }
        
        let viewFrame = self.frame
        if !viewFrame.minY.isLessThanOrEqualTo(0.0) && viewFrame.minY.isLessThanOrEqualTo(superviewSafeAreaInsets.top) {
            self.top?.constant = -viewFrame.minY
        } else {
            self.top?.constant = 0.0
        }
        if viewFrame.maxY.isLess(than: superviewBounds.maxY) && !viewFrame.maxY.isLess(than: superviewBounds.maxY - superviewSafeAreaInsets.bottom) {
            self.bottom?.constant = superviewBounds.maxY - viewFrame.maxY
        } else {
            self.bottom?.constant = 0.0
        }
        if !viewFrame.minX.isLessThanOrEqualTo(0.0) && viewFrame.minX.isLessThanOrEqualTo(superviewSafeAreaInsets.left) {
            self.left?.constant = -viewFrame.minX
        } else {
            self.left?.constant = 0.0
        }
        if viewFrame.maxX.isLess(than: superviewBounds.maxX) && !viewFrame.maxX.isLess(than: superviewBounds.maxX - superviewSafeAreaInsets.right) {
            self.right?.constant = superviewBounds.maxX - viewFrame.maxX
        } else {
            self.right?.constant = 0.0
        }
    }
}
