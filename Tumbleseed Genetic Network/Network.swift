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

var nodeHistoryNumber = 0
var innovationNumber = 0

class Network {
    // Nodes that act as inputs and outputs
    var inputNodes: [InputNode] = []
    var outputNodes: [OutputNode] = []
    
    // All nodes in the network, including input and output nodes
    var nodes: [Node] = []
    
    var fitness: Double = 0.0
    
    var nodeGenes: [NodeGene] {
        var genes = [NodeGene]()
        for node in nodes {
            let nodeType: NodeGene.NodeType!
            if node is OutputNode {
                nodeType = .output
            } else if node is InputNode {
                nodeType = .input
            } else {
                nodeType = .hidden
            }
            genes.append(NodeGene(nodeNumber: node.historyNumber, nodeType: nodeType))
        }
        return genes.sorted { $0.nodeNumber < $1.nodeNumber }
    }
    
    var connectionGenes: [ConnectionGene] {
        var genes = [ConnectionGene]()
        for node in nodes {
            for connection in node.connections {
                genes.append(ConnectionGene(inNumber: node.historyNumber, outNumber: connection.node.historyNumber, weight: connection.weight, enabled: connection.enabled, innovationNumber: connection.innovationNumber))
            }
        }
        return genes.sorted { $0.innovationNumber < $1.innovationNumber }
    }
    
    init(numInputs: Int, numOutputs: Int) {
        for _ in 0..<numInputs {
            let node = InputNode()
            self.inputNodes.append(node)
            self.nodes.append(node)
        }
        
        for _ in 0..<numOutputs {
            let node = OutputNode()
            self.outputNodes.append(node)
            self.nodes.append(node)
        }
    }
    
    init() {
        
    }
    
    func process(inputs: [Double]) -> [Double] {
        assert(inputs.count == outputNodes.count, "Input counts do not match.")
        
        for (i, input) in inputNodes.enumerated() {
            input.process(inputs[i])
        }
        
        return outputNodes.map { return $0.value }
    }
    
    func crossover(with network: Network) -> Network {
        let child = Network(numInputs: inputNodes.count, numOutputs: outputNodes.count)
        
        // Matching genes are inherited randomly, disjoint (where one parent doesn't have a gene) and excess (genes at the end) are inherited from the fit parent
        let nodeGenes = (network.nodeGenes, self.nodeGenes)
        let connectionGenes = (network.connectionGenes, self.connectionGenes)
        
        var childGenes = (node: [NodeGene](), connection: [ConnectionGene]())
        
        var j0 = 0, j1 = 0
        while j0 < nodeGenes.0.count && j1 < nodeGenes.1.count {
            if nodeGenes.0[j0].nodeNumber == nodeGenes.1[j1].nodeNumber {
                // Matching gene, inherit randomly (in this case, they're both the same, so just take it from parent 1)
                childGenes.node.append(nodeGenes.0[j0])
                j0 += 1
                j1 += 1
            } else if nodeGenes.0[j0].nodeNumber > nodeGenes.1[j1].nodeNumber{
                // Disjointed gene; if it's the most fit parent, take it, otherwise, leave it
                if self.fitness >= network.fitness {
                    childGenes.node.append(nodeGenes.1[j1])
                }
                j1 += 1
            } else {
                // Disjointed gene; if it's the most fit parent, take it, otherwise, leave it
                if network.fitness >= self.fitness {
                    childGenes.node.append(nodeGenes.0[j0])
                }
                j0 += 1
            }
        }
        
        if j0 < nodeGenes.0.count && network.fitness >= self.fitness {
            // Excess genes; if it's the most fit parent, take it, otherwise, leave it
            for i in j0..<nodeGenes.0.count {
                childGenes.node.append(nodeGenes.0[i])
            }
        }
        
        if j1 < nodeGenes.1.count && self.fitness >= network.fitness {
            // Excess genes; if it's the most fit parent, take it, otherwise, leave it
            for i in j1..<nodeGenes.1.count {
                childGenes.node.append(nodeGenes.1[i])
            }
        }
        
        j0 = 0
        j1 = 0
        while j0 < connectionGenes.0.count && j1 < connectionGenes.1.count {
            if connectionGenes.0[j0].innovationNumber == connectionGenes.1[j1].innovationNumber {
                // Matching gene, inherit randomly
                childGenes.connection.append(rand(low: 0, high: 1) > 0.5 ? connectionGenes.0[j0] : connectionGenes.1[j1])
                j0 += 1
                j1 += 1
            } else if connectionGenes.0[j0].innovationNumber > connectionGenes.1[j1].innovationNumber{
                // Disjointed gene; if it's the most fit parent, take it, otherwise, leave it
                if self.fitness >= network.fitness {
                    childGenes.connection.append(connectionGenes.1[j1])
                }
                j1 += 1
            } else {
                // Disjointed gene; if it's the most fit parent, take it, otherwise, leave it
                if network.fitness >= self.fitness {
                    childGenes.connection.append(connectionGenes.0[j0])
                }
                j0 += 1
            }
        }
        
        if j0 < connectionGenes.0.count && network.fitness >= self.fitness {
            // Excess genes; if it's the most fit parent, take it, otherwise, leave it
            for i in j0..<connectionGenes.0.count {
                childGenes.connection.append(connectionGenes.0[i])
            }
        }
        
        if j1 < connectionGenes.1.count && self.fitness >= network.fitness {
            // Excess genes; if it's the most fit parent, take it, otherwise, leave it
            for i in j1..<connectionGenes.1.count {
                childGenes.connection.append(connectionGenes.1[i])
            }
        }
        
        for nodeGene in childGenes.node {
            // Add all nodes to child
            child.addNode(gene: nodeGene)
        }
        
        for connectionGene in childGenes.connection {
            // Form all connections
            child.addConnection(gene: connectionGene)
        }
        
        child.mutate()
        
        return child
    }
    
    func addNode(gene: NodeGene) {
        switch gene.nodeType {
        case .input:
            let node = InputNode(historyNumber: gene.nodeNumber)
            inputNodes.append(node)
            nodes.append(node)
        case .output:
            let node = OutputNode(historyNumber: gene.nodeNumber)
            outputNodes.append(node)
            nodes.append(node)
        case .hidden:
            let node = Node(historyNumber: gene.nodeNumber)
            nodes.append(node)
        }
    }
    
    func addConnection(gene: ConnectionGene) {
        let inNodes = nodes.filter { $0.historyNumber == gene.inNumber }
        let outNodes = nodes.filter { $0.historyNumber == gene.outNumber }
        assert(inNodes.count == 1 && outNodes.count == 1, "Mismatch in history number")
        
        let inNode = inNodes.first!
        let outNode = outNodes.first!
        
        inNode.connections.append((weight: gene.weight, node: outNode, enabled: gene.enabled, innovationNumber: gene.innovationNumber))
    }
    
    func mutate() {
        let weightMutateChance = 0.25
        let addConnectionChance = 0.05
        let addNodeChance = 0.05
        
        for node in nodes {
            for i in 0..<node.connections.count where rand(low: 0, high: 1) < weightMutateChance {
                node.connections[i].weight += rand(low: -0.05, high: 0.05)
            }
        }
        
        if rand(low: 0, high: 1) < addConnectionChance {
            var node1 = nodes[randInt(low: 0, high: nodes.count-1)]
            while node1.nodeType == .output {
                // If node1 is an output node, get a new one
                node1 = nodes[randInt(low: 0, high: nodes.count-1)]
            }

            // The randInt with a low of inputNodes.count-1 makes it so that node2 cannot be an input node
            var node2 = nodes[randInt(low: inputNodes.count-1, high: nodes.count-1)]
            
            // If node1 already has a connection to node2, reset it
            while node1.hasConnection(to: node2) {
                node2 = nodes[randInt(low: inputNodes.count-1, high: nodes.count-1)]
            }
            
            
            addConnection(gene: ConnectionGene(inNumber: node1.historyNumber, outNumber: node2.historyNumber, weight: rand(low: -1, high: 1), enabled: true, innovationNumber: innovationNumber))
            innovationNumber += 1
        }
        
        if rand(low: 0, high: 1) < addNodeChance {
            // The node that the new node will connect to
            var node = nodes[randInt(low: 0, high: nodes.count-1)]
            while node.nodeType == .output {
                node = nodes[randInt(low: 0, high: nodes.count-1)]
            }
            
            // The number of the connection that this node will replace
            let x = randInt(low: 0, high: node.connections.count-1)
            
            node.connections[x].enabled = false
            
            // Add the new node
            addNode(gene: NodeGene(nodeNumber: nodeHistoryNumber, nodeType: .hidden))
            
            // Add a connection between the origin node and the new node
            addConnection(gene: ConnectionGene(inNumber: node.historyNumber, outNumber: nodeHistoryNumber, weight: 1.0, enabled: true, innovationNumber: innovationNumber))
            innovationNumber += 1
            
            // Add a connection between the new node and the other node that the original was previously connected to
            addConnection(gene: ConnectionGene(inNumber: nodeHistoryNumber, outNumber: node.connections[x].node.historyNumber, weight: node.connections[x].weight, enabled: true, innovationNumber: innovationNumber))
            innovationNumber += 1
            
            nodeHistoryNumber += 1
        }
    }
}

class Node {
    let nodeType: NodeGene.NodeType
    var connections: [(weight: Double, node: Node, enabled: Bool, innovationNumber: Int)]
    
    var historyNumber: Int
    
    convenience init(historyNumber: Int) {
        self.connections = []
        self.historyNumber = historyNumber

        switch self {
        case is OutputNode:
            self.init(type: .output)
        case is InputNode:
            self.init(type: .input)
        default:
            self.init(type: .hidden)
        }
    }
    
    init(type: NodeGene.NodeType) {
        self.nodeType = type
    }

    func activate(_ x: Double) -> Double {
        return atan(x)
    }
    
    func process(_ x: Double) {
        let ax = activate(x)
        for connection in connections {
            connection.node.process(ax * connection.weight)
        }
    }
    
    func hasConnection(to node: Node) -> Bool {
        for connection in connections {
            if connection.node.historyNumber == node.historyNumber {
                return true
            } else {
                if connection.node.hasConnection(to: node) {
                    return true
                }
            }
        }
        return false
    }
}

class InputNode: Node {
    override func process(_ x: Double) {
        for connection in connections {
            connection.node.process(x * connection.weight)
        }
    }
}

class OutputNode: Node {
    var value: Double = 0.0
    
    override func process(_ x: Double) {
        value += x
    }
}

struct NodeGene {
    let nodeNumber: Int
    let nodeType: NodeType
    
    enum NodeType {
        case input, output, hidden
    }
}

struct ConnectionGene {
    let inNumber: Int
    let outNumber: Int
    let weight: Double
    let enabled: Bool
    let innovationNumber: Int
}
