//
//  DragMonitorView.swift
//  Network Mom
//
//  Created by Darrell Root on 11/9/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa
import DLog

class DragMonitorView: NSView {

    weak var monitor: Monitor?
    weak var controllerDelegate: ControllerDelegate?
    private var monitorWindowController: MonitorWindowController?
    var boxes: [NSBox] = []
    
    var selected: Bool = false {
        didSet {
            if selected {
                layer?.borderWidth = 3.0
                
            } else {
                layer?.borderWidth = 1.0
            }
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    convenience init(frame: NSRect, monitor: Monitor) {
        self.init(frame: frame)
        self.monitor = monitor
        self.monitor?.viewDelegate = self
        let bottomBox = NSBox()
        boxes.append(bottomBox)  // boxes[1]
        boxes[1].wantsLayer = true
        boxes[1].boxType = .primary
        addSubview(boxes[1])
        monitor.viewFrame = frame
    }
    override var isFlipped: Bool {
        return true
    }
    override init(frame: NSRect) {
        let topBox = NSBox()
        boxes.append(topBox)  // boxes[0]
        super.init(frame: frame)
        //setFrameSize(NSSize(width: 50, height: 40))
        translatesAutoresizingMaskIntoConstraints = false
        //layer?.backgroundColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        wantsLayer = true
        layer?.borderWidth = 1.0
        layer?.borderColor = CGColor.black
        boxes[0].wantsLayer = true
        boxes[0].boxType = .primary
        boxes[0].titlePosition = .belowTop
        addSubview(boxes[0])
        if let viewFrame = monitor?.viewFrame {
            self.frame = viewFrame
        }
    }
    
    override func viewDidMoveToSuperview() {
        updateFrame()
        //        let widthConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        //        let heightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        //       self.addConstraints([widthConstraint, heightConstraint])
    }
    
    required init?(coder decoder: NSCoder) {
        DLog.log(.dataIntegrity,"init(coder:) has not been implemented")
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        DLog.log(.userInterface,"deallocating drag monitor view \(boxes[0].title)")
    }
    public func updateLabel() {
        //debugPrint("updateLabel")
        if let title = monitor?.label {
            boxes[0].title = title
            DLog.log(.userInterface,"drawing title \(title)")
        } else {
            boxes[0].title = "No title error 2"
        }
        guard boxes.count > 1 else { return }  //no latency box to put data
        let yesterdayLatency = monitor?.latency.lastDay?.value
        let titlePart1: String
        let titlePart2: String
        if yesterdayLatency != nil {
            titlePart2 = String(format: "YDay Latency: %.2fms", yesterdayLatency!)
        } else {
            titlePart2 = "Yesterday Latency: TBD"
        }
        if let currentLatency = monitor?.latency.lastFiveMinute?.value, boxes.count > 1 {
            titlePart1 = String(format: "Latency: %.2fms",currentLatency)
        } else {
            titlePart1 = "Current Latency TBD"
        }
        boxes[1].title = titlePart1 + "\n" + titlePart2
    }
    
    public func updateFrame() {
        //debugPrint("updateFrame")
        updateLabel()
        var maxWidth: CGFloat = 0.0
        var totalHeight: CGFloat = 0.0
        let widthAdjustment: CGFloat = 20.0
        let heightAdjustment: CGFloat = 10.0
        for box in boxes {
            let boxSize = box.title.size(withAttributes: [ NSAttributedString.Key.font: box.titleFont ])
            let adjustedWidth = boxSize.width + widthAdjustment  // without adjustment box too small
            if adjustedWidth > maxWidth {
                maxWidth = adjustedWidth
            }
        }
        for box in boxes {
            let boxSize = box.title.size(withAttributes: [ NSAttributedString.Key.font: box.titleFont ])
            let adjustedHeight = boxSize.height + heightAdjustment  // without adjustment box too small
            box.frame = NSRect(x: 0, y: totalHeight, width: maxWidth, height: adjustedHeight)
            totalHeight += adjustedHeight
        }
        let oldframe = self.frame
        self.frame = NSRect(x: oldframe.minX, y: oldframe.minY, width: maxWidth, height: totalHeight)
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let color = monitor?.status.cgColor {
            boxes[0].layer?.backgroundColor = color
            if boxes.count > 1 {
                if let latencyStatus = monitor?.latencyStatus() {
                    boxes[1].layer?.backgroundColor = latencyStatus.cgColor
                }
            }
        }
        updateLabel()
        super.draw(dirtyRect)
    }
}
extension DragMonitorView {
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 1 {
            if let controllerDelegate = controllerDelegate {
                let shift = event.modifierFlags.rawValue & NSEvent.ModifierFlags.shift.rawValue
                if !selected && shift == 0 {
                    controllerDelegate.deselectAll()
                }
            }
            selected = !selected
        }
        if event.clickCount == 2 {
            DLog.log(.userInterface,"doubleclick")
            if let monitor = monitor {
                monitorWindowController = MonitorWindowController()
                monitorWindowController?.monitor = monitor
                monitorWindowController?.showWindow(self)
            }
        }
        //debugPrint("x \(event.locationInWindow.x) y \(event.locationInWindow.y)")
        DLog.log(.userInterface,"updated view frame location \(frame)")
        monitor?.viewFrame = frame
    }
    
    override func mouseDragged(with event: NSEvent) {
        let newX = frame.minX + event.deltaX
        let newY = frame.minY - event.deltaY
        frame = NSRect(origin: CGPoint(x: newX, y: newY),size: frame.size)
        //debugPrint("dragged x \(event.deltaX) \(event.deltaY)")
    }
}

