//
//  ConstraintsManager.swift
//  Swissquote
//
//  Created by Besarb Zeqiraj on 17.05.16.
//  Copyright © 2016 Swissquote. All rights reserved.
//

import Foundation

public struct ConstraintsManager {
    
    var constraints = [NSLayoutConstraint]()
    let views: [String : Any]?
    let metrics: [String : Any]?
    
    public init(views:[String : Any]? = nil, metrics: [String : Any]? = nil) {
        ConstraintsManager.prepareViews(views: views)
        self.views = views
        self.metrics = metrics
    }
    
    public func activate() {
        NSLayoutConstraint.activate(constraints)
    }
    
    public mutating func add(_ format: String, options opts: NSLayoutFormatOptions = [], metrics: [String : Any]? = nil, views: [String : Any]? = nil) {
        ConstraintsManager.prepareViews(views: views)
        guard let views = views ?? self.views else {
            assertionFailure("ConstraintsManager is missing views")
            return
        }
        
        let metrics = metrics ?? self.metrics
        
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: format, options: opts, metrics: metrics, views: views)
        self.constraints += constraints
    }
    
    public mutating func add(_ constraint: NSLayoutConstraint) {
        constraints.append(constraint)
    }
    
    public mutating func add(item view1: Any, attribute attr1: NSLayoutAttribute, relatedBy relation: NSLayoutRelation, toItem view2: Any?, attribute attr2: NSLayoutAttribute, multiplier: CGFloat = 1.0, constant c: CGFloat = 0.0){
        self.add(NSLayoutConstraint(item: view1, attribute: attr1, relatedBy: relation, toItem: view2, attribute: attr2, multiplier: multiplier, constant: c))
    }
    
    public static func += (left: inout ConstraintsManager, right: NSLayoutConstraint) {
        left.add(right)
    }
    
    public static func += (left: inout ConstraintsManager, right: [NSLayoutConstraint]) {
        left.constraints += right
    }
    
    public static func += (left: inout ConstraintsManager, right: ConstraintsManager) {
        left.constraints += right.constraints
    }
    
    // Helpers
    
    private static func prepareViews(views: [String : Any]?) {
        views?.forEach {
            guard let view = $0.value as? UIView else { return }
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
