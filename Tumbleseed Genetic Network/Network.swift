//
//  Network.swift
//  Tumbleseed Genetic Network
//
//  Created by Jack Erb on 10/5/17.
//  Copyright © 2017 Jack Erb. All rights reserved.
//

import Foundation

func rand(low: Double, high: Double) -> Double {
    return Double(arc4random()) / Double(UInt32.max) * (high - low) + low
}

func randInt(low: Int, high: Int) -> Int {
    return Int(rand(low: Double(low), high: Double(high)))
}

struct Network {
    var nodes: [[Neuron]]
    var numOutputs: Int
    var inputWeights: [Double]
    
    var fitness: Double = 0
    
    let numLayers = 2
    
    init (numInputs: Int, numOutputs: Int, hiddenLayerSize: Int) {
        self.numOutputs = numOutputs
        
        inputWeights = []
        for _ in 0..<numInputs {
            inputWeights.append(rand(low: -1.0, high: 1.0))
        }

        nodes = []
        for i in 0..<numLayers {
            nodes.append([])
            for _ in 0..<hiddenLayerSize {
                nodes[i].append(Node(numInputs: i == 0 ? numInputs : hiddenLayerSize, numOutputs: (i == numLayers - 1) ? numOutputs : hiddenLayerSize))
            }
            nodes[i].append(Bias(numOutputs: (i == numLayers - 1) ? numOutputs : hiddenLayerSize))
        }
    }
    
    func feedFoward(inputs: Input) -> Output {
        assert(inputs.count == inputWeights.count, "Does not match expected number of inputs")
        var output = Output(data: [])
        var input = inputs
        
        for i in 0..<input.count {
            input.data[i] *= inputWeights[i]
        }
        
        for (i,layer) in nodes.enumerated() {
            output = Output(data: Array<Double>(repeating: 0.0, count: (i == nodes.count - 1) ? numOutputs : nodes[0].count - 1))
            for node in layer {
                let nodeOutput = Output(data: node.process(inputs: input).data)
            
                output = output + nodeOutput
            }
            input = Input(data: output.data)
        }
        
        return output
    }
    
    mutating func mutate() {
        for i in 0..<inputWeights.count {
            if rand(low: 0, high: 1) <= 0.25 {
                inputWeights[i] += rand(low: -0.2, high: 0.2)
            }
            
            if rand(low: 0, high: 1) <= 0.05 {
                inputWeights[i] += rand(low: -1, high: 1)
            }
        }
        
        for i in 0..<nodes.count {
            for j in 0..<nodes[i].count {
                nodes[i][j].mutate()
            }
        }
    }
    
    mutating func crossover(with network: Network) {
        assert(nodes.count == network.nodes.count && nodes[0].count == network.nodes[0].count, "Species have a differing number of neurons")
        
        var mutatingChance = 1.00
        while rand(low: 0.0, high: 1.0) < mutatingChance {
            let x = randInt(low: 0, high: nodes.count-1), y = randInt(low: 0, high: nodes[0].count-1), z = randInt(low: 0, high: nodes[x][y].outputWeights.count)
            
            if rand(low: 0, high: 1) < 0.4 {
                nodes[x][y].outputWeights[z] = network.nodes[x][y].outputWeights[z]
            } else {
                nodes[x][y].outputWeights[z] = (network.nodes[x][y].outputWeights[z] + nodes[x][y].outputWeights[z]) / 2
            }
            
            mutatingChance *= 1/2
        }
    }
}

protocol Neuron {
    var outputWeights: [Double] { get set }
    func process(inputs: Input) -> Output
    mutating func mutate()
}

struct Node: Neuron {
    var outputWeights: [Double]
    
    init (numInputs: Int, numOutputs: Int) {
        
        outputWeights = []
        for _ in 0..<numOutputs {
            outputWeights.append(rand(low: -1, high: 1))
        }
    }
    
    func process(inputs: Input) -> Output {
        var value: Double = 0
        for input in inputs.data {
            value += input
        }
        
        //value = 1 / (1 + pow(M_E, -(value / 1000)))
        value = tanh(value)
        
        var output: [Double] = []
        for (i, outputWeight) in outputWeights.enumerated() {
            output.append(0.0)
            output[i] += value * outputWeight
        }
        
        return Output(data: output)
    }
    
    mutating func mutate() {
        for i in 0..<outputWeights.count {
            if rand(low: 0, high: 1) <= 0.25 {
                outputWeights[i] += rand(low: -0.2, high: 0.2)
            }
            
            if rand(low: 0, high: 1) <= 0.05 {
                outputWeights[i] += rand(low: -1, high: 1)
            }
        }
    }
}

struct Bias: Neuron {
    static let bias: Double = 1.0
    var outputWeights: [Double]
    
    init(numOutputs: Int) {
        outputWeights = []
        for _ in 0..<numOutputs {
            outputWeights.append(rand(low: -1, high: 1))
        }
    }
    
    func process(inputs: Input) -> Output {
        return Output(data: outputWeights.map {$0 * Bias.bias})
    }
    
    mutating func mutate() {
        for i in 0..<outputWeights.count {
            if rand(low: 0, high: 1) <= 0.25 {
                outputWeights[i] += rand(low: -0.2, high: 0.2)
            }
            
            if rand(low: 0, high: 1) <= 0.05 {
                outputWeights[i] += rand(low: -1, high: 1)
            }
        }
    }
}

struct Input {
    var data: [Double]
    var count: Int {
        return data.count
    }
}


struct Output {
    var data: [Double]
}

func +(lhs: Output, rhs: Output) -> Output {
    assert(lhs.data.count == rhs.data.count, "Sizes of output structs do no match")
    var output = Array<Double>(repeating: 0.0, count: lhs.data.count)
    for i in 0..<lhs.data.count {
        output[i] += lhs.data[i] + rhs.data[i]
    }
    return Output(data: output)
}

