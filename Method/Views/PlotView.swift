//
//  PlotView.swift
//  Method
//
//  Created by Mark Wang on 8/1/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//
//import AudioKitPlaygrounds
import AudioKit


class PlotView: UIView {
    
    public static func getPlot() -> AKNodeFFTPlot{
        //addTitle("Node FFT Plot")
        let microphone = AKMicrophone()
        AudioKit.output = AKBooster(microphone, gain: 0.0)
        AudioKit.start()
        let plot = AKNodeFFTPlot(microphone, frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        plot.shouldFill = true
        plot.shouldMirror = false
        plot.shouldCenterYAxis = false
        plot.color = AKColor.purple
        plot.gain = 100
        return plot
    }
}
