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

enum ReportType: String {
    case daily
    case weekly
}

class AvailabilityReport {
    
    weak var map: MapWindowController?
    let reportType: ReportType
    let timeInterval: Int
    let totalDuration: Int
    let startTime: Int
    let startDate: Date
    let endTime: Int
    let endDate: Date
    let currentTime: Int
    let dateFormatter = DateFormatter()

    let chartsFormatterBlank = ChartsFormatterBlank()
    let chartsFormatterPercent = ChartsFormatterPercent()
    let chartsFormatterDateShort = ChartsFormatterDateShort()
    let chartsFormatterDateOnly = ChartsFormatterDateOnly()
    let startDateFormatted: String
    let endDateFormatted: String
    let timeZone: String
    var data: [RRDData]?
    var windowAvailability: [Int:Double] = [:]
    var overallAvailability: Double?
    var license: License?

    init(reportType: ReportType, map: MapWindowController?, license: License?) {
        self.map = map
        self.reportType = reportType
        self.license = license
        switch reportType {
        case .daily:
            timeInterval = 3600
            totalDuration = timeInterval * 24
        case .weekly:
            timeInterval = 86400
            totalDuration = timeInterval * 7
        }
        currentTime = Int(Date().timeIntervalSinceReferenceDate)
        endTime = (currentTime / timeInterval) * timeInterval // rounding down to even time interval
        startTime = endTime - totalDuration
        startDate = Date(timeIntervalSinceReferenceDate: Double(startTime))
        endDate = Date(timeIntervalSinceReferenceDate: Double(endTime))
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        startDateFormatted = dateFormatter.string(from: startDate)
        endDateFormatted = dateFormatter.string(from: endDate)
        timeZone = dateFormatter.timeZone?.identifier ?? "unknown time zone"
        switch reportType {
        case .daily:
            data = map?.availability.getData(dataType: .OneHour)
        case .weekly:
            data = map?.availability.getData(dataType: .OneDay)
        }
        var availabilityNumerator = 0.0
        var availabilityDenominator = 0
        if let allAvailability = data {
            for dataPoint in allAvailability {
                if dataPoint.timestamp >= startTime && dataPoint.timestamp < endTime, let value = dataPoint.value {
                    windowAvailability[dataPoint.timestamp] = value
                    availabilityNumerator += value
                    availabilityDenominator += 1
                }
            }
        }
        if availabilityDenominator > 0 {
            overallAvailability = availabilityNumerator / Double(availabilityDenominator)
        } else {
            overallAvailability = nil
        }
    }
    
    func makeHTML() -> String {
        var html: String
        html = """
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"><html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Network Mom Availability \(reportType.rawValue.capitalizingFirstLetter()) Report</title>
<style>
table, th, td {
        border: 1px solid black;
        border-collapse: collapse;
        text-align: left;
}
</style>
</head>
<body>
<h1>Network Mom Availability \(reportType.rawValue.capitalizingFirstLetter()) Report</h1>
<h2>Map: \(map?.name ?? "unknown")</h2>
<h3>Start Date: \(startDateFormatted) \(timeZone)</h3>
<h3>End Date: \(endDateFormatted) \(timeZone)</h3>
"""
        guard windowAvailability.count > 0, let map = map else {
            html += """
<h2>Error: Insufficient availability data available for map report</h2>
</body>
"""
            return html
        }
        if let license = license {
            switch license.getLicenseStatus {
            case .licensed:
                
                html += "<h3>Network Mom License Valid Until \(license.lastLicenseString)</h3>\n"
            case .trial:
                let daysLeft = Int(license.trialSeconds / (3600 * 24))
                html += "<h3>Network Mom Not Licensed, Trial Period Expires in \(daysLeft) days</h3>\n"
            case .expired:
                html += "<h3>Network Mom License Expired, No Data Available</h3>\n"
                html += "<h3>Have the administrator purchase a license or exit the application</h3>\n"
                return html
            case .unknown:
                html += "<h3>Network Mom License Status Unknown</h3>\n"
            
            }
        } else {
            html += "<h3>Network Mom License Status Unknown</h3>\n"
        }
        
        // Start availablity table
        if let overallAvailability = overallAvailability {
            html += "<h3>Overall Availability \(overallAvailability.percentThree)%</h3>\n"
        }
        switch reportType {
        case .daily:
            html += "<table><tr><th>Start Of Hour</th><th>Availability</th></tr>"
        case .weekly:
            html += "<table><tr><th>Start Of Day</th><th>Availability</th></tr>"
        }
        for (timestamp,availabilityPoint) in windowAvailability.sorted(by: { $0.key < $1.key }) {
            let timeDescription = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp)))
            
            html += "<tr><td> \(timeDescription) </td><td {text-align: right;}> \(availabilityPoint.percentThree)</td></tr>\n"
        }
        html += "</table>\n"
        // End availablity table
        var monitorAvailability: [String:Double] = [:]
        for monitor in map.monitors {
            if let lastDayAvailability = monitor.availability.lastDay?.value {
                monitorAvailability[monitor.label] = lastDayAvailability
            }
        }
        // Start bottom 5 availability report
        html += "<h2>Five monitors with worst availability during this interval</h2>\n"
        html += "<table><tr><th>Monitor</th><th>Availablity</th></tr>\n"
        do {
            let monitorList = monitorAvailability.keys.sorted() { monitorAvailability[$0] ?? 0.5 < monitorAvailability[$1] ?? 0.5 }
            for i in 0..<5 {
                if i < monitorList.count, let monitorValue = monitorAvailability[monitorList[i]] {
                    html += "<tr><td>\(monitorList[i])</td><td>\(monitorValue.percentThree)</td>\n"
                }
            }
        }
        html += "</table>\n"
        // End bottom 5 availability report
        
        // Start top 5 availability report
        html += "<h2>Five monitors with best availability during this interval</h2>\n"
        html += "<table><tr><th>Monitor</th><th>Availablity</th></tr>\n"
        do {
            let monitorList = monitorAvailability.keys.sorted() { monitorAvailability[$0] ?? 0.5 > monitorAvailability[$1] ?? 0.5 }
            for i in 0..<5 {
                if i < monitorList.count, let monitorValue = monitorAvailability[monitorList[i]] {
                    html += "<tr><td>\(monitorList[i])</td><td>\(monitorValue.percentThree)</td>\n"
                }
            }
        }
        html += "</table>\n"
        // End top 5 availability report
        
        // Start Gray report
        html += "<h2>Monitors which have not resonded since last Network Mom reboot</h2>\n"
        html += "<h3>These are not included in availability data calculations</h3>\n"
        html += "<table><tr><th>Monitor</th><th>Status</th></tr>\n"
        for monitor in map.monitors {
            if monitor.status == .Gray {
                html += "<tr><td>\(monitor.label)</td><td>Never online</td></tr>\n"
            }
        }
        html += "</table></n>"
        
        if reportType == .daily {
            // Start Latency Increase report
            var monitorTodayLatency: [String:Double] = [:]
            var monitorYesterdayLatency: [String:Double] = [:]
            var monitorLatencyIncrease: [String:Double] = [:]
            var priorDate: String?
            var todayDate: String?
            for monitor in map.monitors {
                if let todayTimestamp = monitor.latency.lastDay?.timestamp ,let todayLatency = monitor.latency.lastDay?.value, let yesterdayTimestamp = monitor.latency.priorDay?.timestamp, let yesterdayLatency = monitor.latency.priorDay?.value {
                    monitorTodayLatency[monitor.label] = todayLatency
                    monitorYesterdayLatency[monitor.label] = yesterdayLatency
                    monitorLatencyIncrease[monitor.label] = todayLatency / yesterdayLatency
                    if priorDate == nil {
                        priorDate = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(yesterdayTimestamp)))
                    }
                    if todayDate == nil {
                        todayDate = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(todayTimestamp)))
                    }
                }
            }
            if monitorLatencyIncrease.count > 0 {
                html += "<h2>Five monitors with largest recent percentage latency increase</h2>\n"
                var count = 0
                for (monitorKey,_) in monitorLatencyIncrease.sorted( by: {$0.value > $1.value}){
                    if count == 0 {
                        if let priorDate = priorDate {
                            html += "<h3>Prior period start \(priorDate)</h3>\n"
                        }
                        if let todayDate = todayDate {
                            html += "<h3>Current period start \(todayDate)</h3>\n"
                        }
                        html += "<table><tr><th>Monitor</th><th>Prior Period Latency (msec)</th><th>Current Period Latency (msec)</th><th>Increase Factor</th></tr>\n"
                    }
                    if count < 5, let monitorYesterdayLatency = monitorYesterdayLatency[monitorKey], let monitorTodayLatency = monitorTodayLatency[monitorKey], let monitorLatencyIncrease = monitorLatencyIncrease[monitorKey] {
                        html += "<tr><td>\(monitorKey)</td><td>\(monitorYesterdayLatency.twoPlaces)</td><td>\(monitorTodayLatency.twoPlaces)</td><td>\((monitorLatencyIncrease).threePlaces)</tr>\n"
                    }
                    count += 1
                }
                html += "</table></n>"
            } else {
                html += "<h2>Monitor Latency Increase Data Not Available</h2>\n"
            }
            // End Latency Increase Report
        }
        
        html += "<p>\n"
        html += "</body>\n"
        return html
    }
    func makeChart() -> LineChartView {
        
        let lineChart = LineChartView()
        guard windowAvailability.count > 0 else {
            return lineChart    // returning empty linechart if no data
        }
        var minY = 1.0
        var chartDataEntry: [ChartDataEntry] = []
        for dataPoint in windowAvailability.sorted(by: { $0.key < $1.key }) {
            chartDataEntry.append(ChartDataEntry(x: Double(dataPoint.key), y: dataPoint.value))
            if dataPoint.value < minY {
                minY = dataPoint.value
            }
        }
        let line1 = LineChartDataSet(values: chartDataEntry, label: "Availability")
        line1.valueFormatter = chartsFormatterBlank
        line1.colors = [NSColor.systemBlue]
        let lineChartData = LineChartData()
        lineChartData.addDataSet(line1)
        let yAxisMinimum: Double
        switch minY {
        case ..<0.9:
            yAxisMinimum = 0.0
        case (0.9..<0.99):
            yAxisMinimum = 0.9
        case (0.99..<0.999):
            yAxisMinimum = 0.99
        case (0.999..<0.9999):
            yAxisMinimum = 0.999
        case 0.9999...:
            yAxisMinimum = 0.9999
        default:
            yAxisMinimum = 0.0
        }
        lineChart.rightAxis.axisMinimum = yAxisMinimum
        lineChart.rightAxis.axisMaximum = 1.0
        lineChart.leftAxis.axisMinimum = yAxisMinimum
        lineChart.leftAxis.axisMaximum = 1.0
        lineChart.xAxis.valueFormatter = chartsFormatterDateShort
        lineChart.leftAxis.valueFormatter = chartsFormatterPercent
        lineChart.rightAxis.valueFormatter = chartsFormatterPercent
        lineChart.xAxis.granularity = 3600.0
        lineChart.xAxis.labelRotationAngle = -90
        lineChart.data = lineChartData

        return lineChart
    }
    func makeView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
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
