//
//  AvailabilityReport.swift
//  Network Mom Availability
//
//  Created by Darrell Root on 1/25/19.
//  Copyright © 2019 Darrell Root LLC. All rights reserved.
//

import Foundation
import Cocoa
import Charts

class AvailabilityReport {
    
    let chartsFormatterBlank = ChartsFormatterBlank()
    let chartsFormatterPercent = ChartsFormatterPercent()
    let chartsFormatterDateShort = ChartsFormatterDateShort()
    let chartsFormatterDateOnly = ChartsFormatterDateOnly()

    init() {
    }
    
    func makeChart() -> LineChartView {
        let lineChart = LineChartView()
        var chartDataEntry: [ChartDataEntry] = []
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

        return lineChart
    }
    func makeView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 100, width: 200, height: 200))
        let lineChart = makeChart()
        let textFields = [
            "lineChart": lineChart,
        ]
        view.translatesAutoresizingMaskIntoConstraints = false
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineChart)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[lineChart]|", options: [], metrics: nil, views: textFields))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[lineChart]|", options: [], metrics: nil, views: textFields))

        return view
    }
}
