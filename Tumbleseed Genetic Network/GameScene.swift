//
//  GameScene.swift
//  Tumbleseed Genetic Network
//
//  Created by Jack Erb on 10/5/17.
//  Copyright © 2017 Jack Erb. All rights reserved.
//

import SpriteKit
import GameplayKit
import Foundation

struct BitMasks {
    static let ball     : UInt32  =  0x1 << 1
    static let hole     : UInt32  =  0x1 << 2
    static let wall     : UInt32  =  0x1 << 3
    static let detector : UInt32  =  0x1 << 4
    static let bar      : UInt32  =  0x1 << 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var label = SKLabelNode(text: "Generation: 0")
    private var generationNum = 0
    
    var pause = false
    
    let barSpeed = 4
    
    var keys: [KeyCode: Bool] = Dictionary()
    
    let holeRadius = 50
    let numHoles = 9
    var holes = [SKShapeNode]()
    
    var frameCount = 0
    var highestFitness: (fitness: Double, ball: SKShapeNode?) = (0.0, nil)
    
    var specimens = [(bar: SKShapeNode, ball: SKShapeNode, network: Network, isDead: Bool, lastPosition: LastPosition)]()
    
    var detectors = [SKShapeNode]()
    
    override func didMove(to view: SKView) {
        addChild(label)
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0)
        let leftWall = SKShapeNode(rectOf: CGSize(width: 5, height: view.frame.height * 2))
        leftWall.position.x = -view.frame.width / 2
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.frame.size)
        leftWall.physicsBody?.affectedByGravity = false
        leftWall.physicsBody?.collisionBitMask = 0
        leftWall.physicsBody?.categoryBitMask = BitMasks.wall
        leftWall.physicsBody?.contactTestBitMask = 0
        leftWall.name = "wall"
        addChild(leftWall)
        
        let rightWall = SKShapeNode(rectOf: CGSize(width: 5, height: view.frame.height * 2))
        rightWall.position.x = view.frame.width / 2
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.frame.size)
        rightWall.physicsBody?.affectedByGravity = false
        rightWall.physicsBody?.collisionBitMask = 0
        rightWall.physicsBody?.categoryBitMask = BitMasks.wall
        leftWall.physicsBody?.contactTestBitMask = 0
        rightWall.name = "wall"
        addChild(rightWall)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        
        speed *= 1.5
        
        
        let specimenCount = 20
        for i in 0..<specimenCount {
            let bar = SKShapeNode(rectOf: CGSize(width: view.frame.width * 1.5, height: 10))
            bar.physicsBody = SKPhysicsBody(rectangleOf: bar.frame.size)
            bar.physicsBody?.isDynamic = false
            bar.physicsBody?.categoryBitMask = BitMasks.bar << (UInt32(i) + 1)
            bar.fillColor = .brown
            addChild(bar)
            
            let ball = SKShapeNode(circleOfRadius: 20)
            ball.fillColor = .red
            ball.position.y = 100
            ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
            ball.physicsBody?.linearDamping = 0.4
            ball.physicsBody?.categoryBitMask = BitMasks.ball
            ball.physicsBody?.collisionBitMask = bar.physicsBody!.categoryBitMask | BitMasks.wall
            ball.physicsBody?.contactTestBitMask = BitMasks.hole
            ball.name = "ball"
            
            
            addChild(ball)
            
            specimens.append((bar: bar, ball: ball, network: Network(numInputs: 3, numOutputs: 2, hiddenLayerSize: 7), isDead: false, lastPosition: LastPosition()))
        }
        
        
        physicsWorld.contactDelegate = self
        
        //let holes: [(x: Int, y: Int)] = [(0, 200), (-330, 300), (280, 175), (135, 345), (-200, 430), (100, 500), (180, 520), (-45, 375), (387, 318), (-394, 135), (-190, 206), (-318, 490), (275 ,419), (-126, 277)]
        for pos in holes {
            let hole = SKShapeNode(circleOfRadius: CGFloat(holeRadius))
            hole.fillColor = .black
            hole.position = CGPoint(x: pos.x, y: pos.y)
            hole.physicsBody = SKPhysicsBody(circleOfRadius: 2 * CGFloat(holeRadius) / 3)
            hole.physicsBody?.affectedByGravity = false
            hole.physicsBody?.categoryBitMask = BitMasks.hole
            hole.physicsBody?.contactTestBitMask = 0
            hole.physicsBody?.collisionBitMask = 0
            hole.zPosition = -2
            hole.name = "hole"
            addChild(hole)
            
            self.holes.append(hole)
        }
        
        for i in 0..<8 {
            let path = CGMutablePath()
            path.move(to: CGPoint.zero)
            path.addLine(to: CGPoint(x: sin(1/4 * Double(i) * Double.pi) * 100, y: cos(1/4 * Double(i) * Double.pi) * 100))
            
            let detector = SKShapeNode()
            detector.path = path
            detector.lineWidth = 2
            detector.strokeColor = .green
            detector.zPosition = -3
            detector.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            detector.physicsBody?.isDynamic = true
            detector.physicsBody?.categoryBitMask = BitMasks.detector
            detector.physicsBody?.contactTestBitMask = BitMasks.hole | BitMasks.wall
            detector.strokeColor = .clear
            addChild(detector)
            
            detectors.append(detector)
        }
        
        for _ in 0..<5{
            detectors[2].removeFromParent()
            detectors.remove(at: 2)
        }

    }
    
    override func mouseDown(with event: NSEvent) {
        let location = view!.convert(event.locationInWindow, to: view!.scene!)
        print(location)
        
        let hole = SKShapeNode(circleOfRadius: CGFloat(holeRadius))
        hole.fillColor = .black
        hole.position = location
        hole.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(holeRadius) / 2)
        hole.physicsBody?.affectedByGravity = false
        hole.physicsBody?.categoryBitMask = BitMasks.hole
        hole.physicsBody?.contactTestBitMask = 0
        hole.physicsBody?.collisionBitMask = 0
        hole.zPosition = -2
        hole.name = "hole"
        addChild(hole)
        
        self.holes.append(hole)
    }
    
    override func keyDown(with event: NSEvent) {
        if let keyCode = KeyCode(rawValue: event.keyCode) {
            keys[keyCode] = true
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let keyCode = KeyCode(rawValue: event.keyCode) {
            keys[keyCode] = false
            
            if keyCode == .A {
                for i in 0..<specimens.count {
                    specimens[i].isDead = true
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /*let bar = specimens[0].bar
        let ball = specimens[0].ball
        if keys[.W] ?? false && bar.zRotation > -CGFloat(Double.pi / 18) {
            bar.position.y += speed / 2
            bar.zRotation -= atan(speed / view!.frame.width)
        }
        if keys[.I] ?? false && bar.zRotation < CGFloat(Double.pi / 18) {
            bar.position.y += speed / 2
            bar.zRotation += atan(speed / view!.frame.width)
        }
        if keys[.K] ?? false && bar.zRotation > -CGFloat(Double.pi / 18) {
            bar.position.y -= speed / 2
            bar.zRotation -= atan(speed / view!.frame.width)
        }
        if keys[.S] ?? false && bar.zRotation < CGFloat(Double.pi / 18) {
            bar.position.y -= speed / 2
            bar.zRotation += atan(speed / view!.frame.width)
        }
        
        for detector in detectors {
            detector.position = ball.position
            detector.strokeColor = .green
            
            let contactedBodies = detector.physicsBody!.allContactedBodies().filter { $0.node!.name! == "hole" }
            if contactedBodies.count > 0 {
                detector.strokeColor = .red
                let hole = contactedBodies[0]
                
                let dist = hole.node!.position.dist(to: ball.position)
                print((dist - 20) / (100))
            } else {
                detector.strokeColor = .green
                print(1)
            }
        }*/
        
        
        
        var aliveCount = 0
        for (offset: i, element: (bar: bar, ball: ball, network: network, isDead: isDead, lastPosition: lastPos)) in specimens.enumerated() {
            if isDead {
                continue
            }
            
            var input = [Double]()
            for detector in detectors {
                detector.position = ball.position

                let contactedBodies = detector.physicsBody!.allContactedBodies()
            
                var x = 0.0
                for node in contactedBodies {
                    switch node.node!.name! {
                    case "hole":
                        let hole = contactedBodies[0]
                        
                        let dist = hole.node!.position.dist(to: ball.position)
                        x = dist / 100
                        detector.strokeColor = .red
                    case "wall" where x <= 0.0:
                        x = 1
                        detector.strokeColor = .blue
                    default:
                        break
                    }
                }
                if x == 0 {
                    detector.strokeColor = .green
                    input.append(0)
                } else {
                    input.append(x)
                }
            }

            let output = network.process(inputs: input)
            
            if output[0] > 0.5 && bar.zRotation > -CGFloat(Double.pi / 36) {
                bar.position.y += speed / 2
                bar.zRotation -= atan(speed / view!.frame.width)
            }
            if output[1] > 0.5 && bar.zRotation < CGFloat(Double.pi / 36) {
                bar.position.y += speed / 2
                bar.zRotation += atan(speed / view!.frame.width)
            }
            if output[0] < -0.5 && bar.zRotation > -CGFloat(Double.pi / 36) {
                bar.position.y -= speed / 2
                bar.zRotation -= atan(speed / view!.frame.width)
            }
            if output[1] < -0.5 && bar.zRotation < CGFloat(Double.pi / 36) {
                bar.position.y -= speed / 2
                bar.zRotation += atan(speed / view!.frame.width)
            }
            
            if lastPos.pos.distSqr(to: ball.position) < 10 {
                specimens[i].lastPosition.numFramesHasNotMoved += 1
                
                if lastPos.numFramesHasNotMoved >= 60 {
                    specimens[i].isDead = true
                    ball.physicsBody?.isDynamic = false
                    ball.fillColor = .white
                }
            } else {
                specimens[i].lastPosition.numFramesHasNotMoved = 0
                specimens[i].lastPosition.pos = ball.position
            }
            
            specimens[i].network.fitness = Double(ball.position.y)
            
            if specimens[i].network.fitness > highestFitness.fitness {
                ball.alpha = 1.0
                bar.alpha = 1.0
                
                highestFitness.fitness = specimens[i].network.fitness
                highestFitness.ball = ball
            } else if ball !== highestFitness.ball {
                ball.alpha = 0.15
                bar.alpha = 0.15
            }
            
            if network.fitness < 0 {
                specimens[i].isDead = true
                ball.physicsBody?.isDynamic = false
                ball.fillColor = .white
                ball.alpha = 0.05
                bar.alpha = 0.05
            }
            
            if ball.position.y > 580 {
                specimens[i].isDead = true
                ball.physicsBody?.isDynamic = false
                ball.fillColor = .white
                ball.alpha = 0.05
                bar.alpha = 0.05
            }
            
            if frameCount > 180 && network.fitness < 90 {
                specimens[i].isDead = true
                ball.physicsBody?.isDynamic = false
                ball.fillColor = .white
                ball.alpha = 0.05
                bar.alpha = 0.05
            }
            
            aliveCount += 1
        }
        
        if let ball = highestFitness.ball {
            for detector in detectors {
                detector.position = ball.position
                let contactedBodies = detector.physicsBody!.allContactedBodies()
                
                detector.strokeColor = .green
                for node in contactedBodies {
                    switch node.node!.name! {
                    case "hole":
                        detector.strokeColor = .red
                    case "wall" where detector.strokeColor != .red:
                        detector.strokeColor = .blue
                    default:
                        break
                    }
                }
            }
        }
        
        frameCount += 1
        
        if aliveCount == 0 {
            train()
        }
    }
    
    func train() {
        specimens.sort { $0.network.fitness > $1.network.fitness }
        
        for i in (specimens.count - specimens.count / 4)..<specimens.count {
            specimens[i].network = specimens[Int(rand(low: 0, high: Double(specimens.count/6)))].network
        }
        
        for i in 0..<specimens.count-1 {
            specimens[i].network.crossover(with: specimens[i+1].network)
        }
        
        for i in 1..<specimens.count {
            specimens[i].network.mutate()
        }
        
        generationNum += 1
        label.text = "Generation: \(generationNum)"
        
        reset()
    }
    
    func reset() {
        for (i,specimen) in specimens.enumerated() {
            let ball = specimen.ball
            let bar = specimen.bar
            
            ball.position.x = 0
            ball.position.y = 50
            bar.position = CGPoint.zero
            
            bar.zRotation = 0
            bar.physicsBody = SKPhysicsBody(rectangleOf: bar.frame.size)
            bar.physicsBody?.isDynamic = false
            bar.physicsBody?.categoryBitMask = BitMasks.bar << (UInt32(i) + 1)

            ball.zRotation = 0
            ball.fillColor = .red
            ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
            ball.physicsBody?.linearDamping = 0.4
            ball.physicsBody?.categoryBitMask = BitMasks.ball
            ball.physicsBody?.collisionBitMask = bar.physicsBody!.categoryBitMask | BitMasks.wall
            ball.physicsBody?.contactTestBitMask = BitMasks.hole
            
            specimens[i].isDead = false
        }
        frameCount = 0
        highestFitness.fitness = 0
        highestFitness.ball = nil
        
        for hole in holes {
            hole.position = CGPoint(x: CGFloat(rand(low: Double(-frame.width/3), high: Double(frame.width/3))), y: CGFloat(rand(low: 120, high: Double(frame.height * 10/11))))

        }
        
        holes[0].position = CGPoint(x: 0, y: 210)
        holes[1].position = CGPoint(x: 367, y: 463)
        holes[2].position = CGPoint(x: -377, y: 450)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA
        let nodeB = contact.bodyB
        
        guard nodeA.categoryBitMask & BitMasks.ball != 0 && nodeB.categoryBitMask & BitMasks.hole != 0 else {
            return
        }
        
        let specimenNum = Int(log2(Double(nodeA.collisionBitMask)) - 6)
        specimens[specimenNum].isDead = true
        specimens[specimenNum].ball.fillColor = .white
        specimens[specimenNum].ball.alpha = 0.05
        specimens[specimenNum].bar.alpha = 0.05
        nodeA.isDynamic = false
    }
}

extension CGPoint {
    func distSqr(to point: CGPoint) -> Double {
        let xDist = point.x - self.x
        let yDist = point.y - self.y
        return Double(xDist * xDist + yDist * yDist)
    }
    
    func dist(to point: CGPoint) -> Double {
        return sqrt(distSqr(to: point))
    }
}

struct LastPosition {
    var pos = CGPoint.zero
    var numFramesHasNotMoved = 0
    
    init() {}
}
