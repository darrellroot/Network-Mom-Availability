//
//  ChartsFormatter.swift
//  Network Mom
//
//  Created by Darrell Root on 11/7/18.
//  Copyright © 2018 Darrell Root LLC. All rights reserved.
//

import Foundation
import Charts

class ChartsFormatterBlank: IValueFormatter {
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        // We do not want labels on each data point in our graph
        return ""
    }
}
class ChartsFormatterPercent: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        // y-value percent
        return "\(Int(value*100))%"
    }
}
class ChartsFormatterMsec: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        // y-value percent
        return "\(Int(value))msec"
    }
}
class ChartsFormatterDateShort: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSinceReferenceDate: value)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from:date)
    }
}
class ChartsFormatterDateOnly: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSinceReferenceDate: value)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from:date)
    }
}

