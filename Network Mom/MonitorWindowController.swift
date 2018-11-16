//
//  MonitorWindowController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/5/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa
import Charts

class MonitorWindowController: NSWindowController {
    
    @IBOutlet weak var customView: NSView!
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var availabilityChart: LineChartView!
    @IBOutlet weak var commentLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var typeLabel: NSTextField!
    @IBOutlet weak var stackView: FlipStackView!
    @IBOutlet weak var selectButtonDataOutlet: NSPopUpButton!
    
    let chartsFormatterBlank = ChartsFormatterBlank()
    let chartsFormatterPercent = ChartsFormatterPercent()
    let chartsFormatterDateShort = ChartsFormatterDateShort()
    let chartsFormatterDateOnly = ChartsFormatterDateOnly()
    let chartsFormatterMsec = ChartsFormatterMsec()
    
    weak var monitor: Monitor?
    
    let dateFormatter = DateFormatter()
    
    convenience init() {
        self.init(windowNibName: "MonitorWindowController")
    }
    deinit {
        debugPrint("deinit MonitorWindowController")
    }
    
    @IBAction func commentField(_ sender: NSTextField) {
        debugPrint("comment field action")
        monitor?.comment = sender.stringValue
        print("sender string value \(sender.stringValue) monitor comment \(String(describing: monitor?.comment))")
        updateTitle()
    }
    
    private func updateTitle() {
        debugPrint("updateTitle")
        if let monitor = monitor, let window = window {
            window.title = monitor.label.replacingOccurrences(of: "\n", with: "   ")
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        if let monitor = monitor {
            updateTitle()
            commentLabel.stringValue = monitor.comment ?? ""
            statusLabel.stringValue = monitor.status.rawValue
            typeLabel.stringValue = monitor.type.rawValue
            makeAvailabilityChart(dataType: MonitorDataType.FiveMinute)
            
            if monitor.latencyEnabled {
                availabilityChart.isHidden = false
                makeLatencyChart(dataType: MonitorDataType.FiveMinute)
            } else {
                availabilityChart.isHidden = true
            }
        } else {
            commentLabel.stringValue = ""
            statusLabel.stringValue = ""
            typeLabel.stringValue = ""
        }
        updateFrames()
    }
    func updateFrames() {
        print("in update frames")
        let standardHeight: CGFloat = 321.0
        if monitor?.latencyEnabled ?? false {
            print("detected latency enable")
            availabilityChart.isHidden = false
            
            let heightConstraint = NSLayoutConstraint(item: availabilityChart, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: standardHeight)
            availabilityChart.addConstraint(heightConstraint)
            availabilityChart.updateConstraints()
        } else {
            availabilityChart.isHidden = true
            let heightConstraint = NSLayoutConstraint(item: stackView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: standardHeight * 2)
            stackView.addConstraint(heightConstraint)
            availabilityChart.updateConstraints()
        }
        
        stackView.needsLayout = true
        stackView.needsDisplay = true
        
    }
    
    @IBAction func selectDataButton(_ sender: NSPopUpButton) {
        let choice = sender.indexOfSelectedItem
        switch choice {
        case 0: makeAvailabilityChart(dataType: MonitorDataType.FiveMinute)
        case 1: makeAvailabilityChart(dataType: MonitorDataType.ThirtyMinute)
        case 2: makeAvailabilityChart(dataType: MonitorDataType.TwoHour)
        case 3: makeAvailabilityChart(dataType: MonitorDataType.OneDay)
        case 4: makeAvailabilityChart(dataType: nil)
        default: fatalError("should not get here")
        }
        if monitor?.latencyEnabled ?? false {
            switch choice {
            case 0: makeLatencyChart(dataType: MonitorDataType.FiveMinute)
            case 1: makeLatencyChart(dataType: MonitorDataType.ThirtyMinute)
            case 2: makeLatencyChart(dataType: MonitorDataType.TwoHour)
            case 3: makeLatencyChart(dataType: MonitorDataType.OneDay)
            case 4: makeLatencyChart(dataType: nil)
            default: fatalError("should not get here")
            }
        }
    }
    private func makeLatencyChart(dataType: MonitorDataType?) {
        var chartDataEntry: [ChartDataEntry] = []
        if let dataType = dataType, let rrdDataSet = monitor?.latency?.getData(dataType: dataType) {
            for rrdData in rrdDataSet {
                if let latency = rrdData.value {
                    let time = Double(rrdData.timestamp)
                    let value = ChartDataEntry(x: time, y: latency)
                    chartDataEntry.append(value)
                }
            }
        } else { // dataType is nil so need test data
            chartDataEntry.append(ChartDataEntry(x: 563227200, y: 21.0))
            chartDataEntry.append(ChartDataEntry(x: 563227500, y: 31.0))
            chartDataEntry.append(ChartDataEntry(x: 563227800, y: 16.2))
            chartDataEntry.append(ChartDataEntry(x: 563228100, y: 33.0))
            chartDataEntry.append(ChartDataEntry(x: 563228400, y: 22.0))
            chartDataEntry.append(ChartDataEntry(x: 563228700, y: 55.0))
            chartDataEntry.append(ChartDataEntry(x: 563229000, y: 88.2))
            chartDataEntry.append(ChartDataEntry(x: 563229300, y: 33.0))
            chartDataEntry.append(ChartDataEntry(x: 563229600, y: 12.0))
            chartDataEntry.append(ChartDataEntry(x: 563229900, y: 44.0))
            chartDataEntry.append(ChartDataEntry(x: 563230200, y: 22.3))
            chartDataEntry.append(ChartDataEntry(x: 563230500, y: 22.0))
            chartDataEntry.append(ChartDataEntry(x: 563230800, y: 14.0))
            chartDataEntry.append(ChartDataEntry(x: 563231100, y: 44.0))
        }

        let line1 = LineChartDataSet(values: chartDataEntry, label: "Latency")
        line1.valueFormatter = chartsFormatterBlank
        line1.colors = [NSColor.systemRed]
        let data = LineChartData()
        data.addDataSet(line1)
        availabilityChart.rightAxis.axisMinimum = 0.0
        availabilityChart.leftAxis.axisMinimum = 0.0
        availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
        availabilityChart.leftAxis.valueFormatter = chartsFormatterMsec
        availabilityChart.rightAxis.valueFormatter = chartsFormatterMsec
        
        if let choice = selectButtonDataOutlet?.indexOfSelectedItem {
        switch choice {
            case 0:
                availabilityChart.xAxis.granularity = 3600.0  // 5min data increments
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
            case 1:
                availabilityChart.xAxis.granularity = 3600.0 * 6
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
            case 2:
                availabilityChart.xAxis.granularity = 3600.0 * 24
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateOnly
            case 3:
                availabilityChart.xAxis.granularity = 3600.0 * 24 * 30
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateOnly
            case 4: // test data
                availabilityChart.xAxis.granularity = 3600.0
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
            default: // should not get here
                availabilityChart.xAxis.granularity = 3600.0
                availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
            }
        } else {
            availabilityChart.xAxis.granularity = 3600.0
            availabilityChart.xAxis.valueFormatter = chartsFormatterDateShort
        }
        availabilityChart.xAxis.labelRotationAngle = -90
        availabilityChart.data = data
    }
    private func makeAvailabilityChart(dataType: MonitorDataType?) {
        var chartDataEntry: [ChartDataEntry] = []
        if let dataType = dataType, let rrdDataSet = monitor?.availability.getData(dataType: dataType) {
            for rrdData in rrdDataSet {
                if let availability = rrdData.value {
                    let time = Double(rrdData.timestamp)
                    let value = ChartDataEntry(x: time, y: availability)
                    chartDataEntry.append(value)
                    //debugPrint("chart data point x \(time) y \(availability)")
                }
            }
        } else { // dataType is nil so need test data
            chartDataEntry.append(ChartDataEntry(x: 563227200, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563227500, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563227800, y: 0.2))
            chartDataEntry.append(ChartDataEntry(x: 563228100, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563228400, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563228700, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563229000, y: 0.2))
            chartDataEntry.append(ChartDataEntry(x: 563229300, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563229600, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563229900, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563230200, y: 0.3))
            chartDataEntry.append(ChartDataEntry(x: 563230500, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563230800, y: 0.0))
            chartDataEntry.append(ChartDataEntry(x: 563231100, y: 0.0))
        }

        let line1 = LineChartDataSet(values: chartDataEntry, label: "Availability")
        line1.valueFormatter = chartsFormatterBlank
        line1.colors = [NSColor.systemBlue]
        let data = LineChartData()
        data.addDataSet(line1)
        
        lineChart.rightAxis.axisMinimum = 0.0
        lineChart.rightAxis.axisMaximum = 1.0
        lineChart.leftAxis.axisMinimum = 0.0
        lineChart.leftAxis.axisMaximum = 1.0
        lineChart.xAxis.valueFormatter = chartsFormatterDateShort
        lineChart.leftAxis.valueFormatter = chartsFormatterPercent
        lineChart.rightAxis.valueFormatter = chartsFormatterPercent
        lineChart.xAxis.granularity = 3600.0
        lineChart.xAxis.labelRotationAngle = -90
        lineChart.data = data
        //lineChart.chartDescription?.text = "5-minute availability data"
    }
}
