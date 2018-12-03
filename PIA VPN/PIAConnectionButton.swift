//
//  PIAConnectionButton.swift
//  PIA VPN
//
//  Created by Jose Antonio Blaya Garcia on 30/11/2018.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation

private struct PIAConnectionButtonSettings {
    static let outsideBorderWidth: CGFloat = 10.0
    static let animatedShapeWidth: CGFloat = 2.0
    static let startAngle: CGFloat = -0.25 * 2 * .pi
    static let endAngle: CGFloat = PIAConnectionButtonSettings.startAngle + 2 * .pi
    static let udpateColorAnimationDuration = 0.3
    static let shapeAnimationDuration = 2
    static let shapeEndAnimationDuration = 0.3
    static let timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.88, 0.09, 0.99)
}

class PIAConnectionButton: UIButton {

    private var isAnimating: Bool = false
    var isOn: Bool = false
    var isIndeterminate: Bool = false
    
    private let circlePathLayer = CAShapeLayer()
    private var circleRadius: CGFloat!
    private var currenStrokeEnd: CGFloat!
    private var displayLink: CADisplayLink!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }

    private func setupView() {
        
        displayLink = CADisplayLink(target: self, selector: #selector(redrawUpdate))

        //Configure the button static color
        self.layer.cornerRadius = self.frame.width/2
        self.layer.borderWidth = PIAConnectionButtonSettings.outsideBorderWidth
        self.layer.borderColor = UIColor.piaGrey2.cgColor
        
        //Configure the Bezierpath to animate
        self.circlePathLayer.strokeEnd = 1
        self.circlePathLayer.frame = bounds
        self.circlePathLayer.lineWidth = PIAConnectionButtonSettings.animatedShapeWidth
        self.circlePathLayer.fillColor = UIColor.clear.cgColor
        self.updateColors()
        self.layer.addSublayer(circlePathLayer)
        self.clipsToBounds = true
        
        //Image
        let vpnImage = Asset.Piax.Dashboard.vpnButton.image.withRenderingMode(.alwaysTemplate)
        self.setImage(vpnImage, for: [])
        
    }
    
    private func circleAnimationPath() -> UIBezierPath {
        self.circleRadius = (self.frame.width - (self.layer.borderWidth*2))/2
        let center = CGPoint(x: self.bounds.width/2,
                             y: self.bounds.height/2)
        return UIBezierPath(arcCenter: center,
                            radius: self.circleRadius,
                            startAngle: PIAConnectionButtonSettings.startAngle,
                            endAngle: PIAConnectionButtonSettings.endAngle,
                            clockwise: true)
    }
    
    private func updateColors() {
        UIView.animate(withDuration: PIAConnectionButtonSettings.udpateColorAnimationDuration) { [weak self] in
            if let weakSelf = self {
                if weakSelf.isOn {
                    weakSelf.circlePathLayer.strokeColor = UIColor.piaGreen.cgColor
                    weakSelf.tintColor = UIColor.piaGreen
                } else {
                    weakSelf.circlePathLayer.strokeColor = UIColor.piaRedDark.cgColor
                    weakSelf.tintColor = UIColor.piaRedDark
                }
                if weakSelf.isIndeterminate {
                    weakSelf.circlePathLayer.strokeColor = UIColor.piaYellowDark.cgColor
                    weakSelf.tintColor = UIColor.piaYellowDark
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        circlePathLayer.frame = bounds
        circlePathLayer.path = circleAnimationPath().cgPath
    }
    
    func startButtonAnimation() {
        
        displayLink.add(to: .current, forMode: .commonModes)

        self.updateColors()

        let duration: CFTimeInterval = CFTimeInterval(PIAConnectionButtonSettings.shapeAnimationDuration)
        
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.fromValue = 0
        end.toValue = 1
        end.beginTime = 0
        end.duration = duration * 0.75
        end.timingFunction = PIAConnectionButtonSettings.timingFunction
        end.fillMode = kCAFillModeForwards
        
        let begin = CABasicAnimation(keyPath: "strokeStart")
        begin.fromValue = 0
        begin.toValue = 1
        begin.beginTime = duration * 0.15
        begin.duration = duration * 0.85
        begin.timingFunction = PIAConnectionButtonSettings.timingFunction
        begin.fillMode = kCAFillModeBackwards

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0
        opacity.toValue = 1
        opacity.beginTime = 0
        opacity.duration = duration * 0.75
        opacity.timingFunction = PIAConnectionButtonSettings.timingFunction
        opacity.fillMode = kCAFillModeForwards

        let group = CAAnimationGroup()
        group.animations = [end, begin, opacity]
        group.duration = duration
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        
        self.circlePathLayer.add(group, forKey: "move")
        isAnimating = true

    }
    
    func stopButtonAnimation() {
        
        self.updateColors()
        self.circlePathLayer.removeAllAnimations()
        self.circlePathLayer.strokeEnd = 1
        self.circlePathLayer.strokeStart = 0
        
        if isAnimating {
            let ending = CABasicAnimation(keyPath: "strokeEnd")
            ending.fromValue = self.currenStrokeEnd
            ending.toValue = 1
            ending.duration = PIAConnectionButtonSettings.shapeEndAnimationDuration
            ending.fillMode = kCAFillModeForwards
            self.circlePathLayer.add(ending, forKey: "move")
            displayLink.remove(from: .current, forMode: .commonModes)
        }
        
        isAnimating = false

    }
    
    @objc func redrawUpdate() {
        if let layer = self.circlePathLayer.presentation() {
            if let value = layer.value(forKey: "strokeEnd") as? CGFloat {
                self.currenStrokeEnd = value
            }
        }
    }

}