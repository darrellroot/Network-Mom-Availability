//
//  MapAvailabilityReportController.swift
//  Network Mom
//
//  Created by Darrell Root on 11/12/18.
//  Copyright © 2018 Root Incorporated. All rights reserved.
//

import Cocoa
import Charts

class MapAvailabilityReportController: NSWindowController {

    weak var delegate: MapWindowController?
    
    @IBOutlet weak var mapNameOutlet: NSTextField!
    @IBOutlet weak var selectDataOutlet: NSPopUpButton!
    @IBOutlet weak var lineChart: LineChartView!
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("MapAvailabilityReportController")
    }
    let chartsFormatterBlank = ChartsFormatterBlank()
    let chartsFormatterPercent = ChartsFormatterPercent()
    let chartsFormatterDateShort = ChartsFormatterDateShort()
    let chartsFormatterDateOnly = ChartsFormatterDateOnly()

    override func windowDidLoad() {
        super.windowDidLoad()
        if let mapName = delegate?.name {
            mapNameOutlet.stringValue = mapName
        }
        makeAvailabilityChart(dataType: MonitorDataType.FiveMinute)
    }
    @IBAction func mapNameAction(_ sender: NSTextField) {
        delegate?.name = mapNameOutlet.stringValue
        window?.title = mapNameOutlet.stringValue
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
    }
    private func makeAvailabilityChart(dataType: MonitorDataType?) {
        var chartDataEntry: [ChartDataEntry] = []
        if let dataType = dataType, let rrdDataSet = delegate?.availability.getData(dataType: dataType) {
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
