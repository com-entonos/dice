//
//  dice.swift
//  dice
//
//  Created by G.J. Parker on 19/9/14.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit
import SceneKit

enum DieType : Int,CaseIterable {
    case dice6 = 6, dice2 = 2, dice4 = 4, dice8 = 8, dice10 = 10, dice12 = 12, dice20 = 20
}

// global variables for icons (is there a better way?)
let smallIcon : [ DieType: UIImage] = [ .dice6:UIImage(named: "diceSMALL")!, .dice2:UIImage(named: "coinSMALL")!, .dice4:UIImage(named: "tetSMALL")!, .dice8:UIImage(named: "octSMALL")!,
                                        .dice10:UIImage(named: "decSMALL")!, .dice12:UIImage(named: "dodSMALL")!, .dice20:UIImage(named: "icoSMALL")!]
let tinyIcon : [ DieType: String] = [ .dice6 : "cubeTinyIcon", .dice2 : "coinTinyIcon", .dice4 : "tetraTinyIcon", .dice8 : "octTinyIcon", .dice10 : "decTinyIcon", .dice12 : "dodTinyIcon", .dice20 : "icoTinyIcon" ]

class Dice : SCNNode {
    // base class for die
    
    //static let pro1toDie = SCNScene(named: "art.scnassets/dice05.scn")!.rootNode.childNodes[0].geometry as! SCNGeometry
    //static let protoDie = SCNScene(named: "art.scnassets/dice05.scn")?.rootNode.childNodes[0]
    //static let protoDie = SCNScene(named: "art.scnassets/coin02.scn")?.rootNode.childNodes[0]
    
    var dieLength : CGFloat   = 0   // side lenghth of die (m)
    var dieMass : CGFloat = 0       // mass of die (kg)
    private var _dieType : DieType = .dice2 // type of die
    var dieInertia : simd_float3 = [ 1, 1, 1 ]    // diagonal moment of inertia
    
    let dieDensity = CGFloat(1200.0)    // density of die (kg/m^3) (acrylic~1200)
    let dieRestitution = CGFloat(0.9)   //(0.95) // how elastic are collisions (die contribution)
    let dieFriction = CGFloat(0.7)  // friction (die contribution)
    var diffuseName = "coin"    // diffuse content of die
    
    var dieCircumR = CGFloat(0) // maximum dimension of die
    var dieInR = CGFloat(0)     // closest distance die can come to floor
    var dieMidR = CGFloat(0)    // some distance to determine if die has finished dynamics

    
    var circumR: Float { // return size of dice length (m)
        get {
            return Float(dieCircumR)
        }
        set (value) {
            dieCircumR = CGFloat(value)
        }
    }
    var inR: Float { // return size of dice length (m)
        get {
            return Float(dieInR)
        }
        set (value) {
            dieInR = CGFloat(value)
        }
    }
    var midR: Float { // return size of dice length (m)
        get {
            return Float(dieMidR)
        }
        set (value) {
            dieMidR = CGFloat(value)
        }
    }
    
    var dieType: DieType { // return size of dice length (m)
        get {
            return _dieType
        }
        set (value) {
            _dieType = value
        }
    }
    var size: Float { // return size of dice length (m)
        get {
            return Float(dieLength)
        }
        set (value) {
            dieLength = CGFloat(value)
        }
    }
    var restitution: CGFloat {
        get { return dieRestitution}
    }
    
    var mass: Float { // return mass of dice (kg)
        get {
            return Float(dieMass)
        }
        set (value) {
            dieMass = CGFloat(value)
        }
    }
    
    var inertiaByMass: simd_float3 {  // return moment of inertial / mass (m^2)
        get {
            return self.dieInertia / Float(self.dieMass)
        }
        set (value) {
            self.dieInertia = value * Float(self.dieMass)
        }
    }
    
   /* common functions */
    func die() {
        let moveAction = SCNAction.moveBy(x: 0, y: -1.1 * dieCircumR * 2 - CGFloat(self.presentation.position.y), z: 0, duration: 0.5)
        let allActions = SCNAction.sequence([moveAction, SCNAction.removeFromParentNode()])
        self.physicsBody?.type = .static
        self.physicsBody?.collisionBitMask = 0
        self.runAction(allActions)
    }
    
    func randomOrientation() -> simd_quatf {  // make an random orientation of the die
/**/
        // create a random quaternion
        var randomV = simd_float4(x: 0, y: 0, z: 0, w: 0)
        for i in 0..<2 {  // generate each component from a normal distribution (we'll use Box-Muller transformation)
            var v1 = Float(0)
            var v2 = Float(0)
            var mag = Float(0)
            repeat {
                v1 = Float.random(in: -1.0...1.0)
                v2 = Float.random(in: -1.0...1.0)
                mag = v1*v1+v2*v2
            } while mag >= 1 || mag == 0
            mag = sqrt( -2 * log(mag) / mag) // ugh
            if i == 0 {
                randomV.w = v1 * mag
                randomV.x = v2 * mag
            } else {
                randomV.y = v1 * mag
                randomV.z = v2 * mag
            }
        }
        return simd_quatf(vector: randomV).normalized  // need to normalize the quaternion
/**/
/*
        // create a random point on unit sphere, r
        let phi = Float.random(in: 0...( 2 * Float.pi))  // random azimuthal angle
        let cost = Float.random(in: -1...1)     // random cos(theta)=z.r, i.e. random polar angle
        let sint = sqrt(max(0,1 - cost * cost)) // corresponding sin(theta)
        var rot = acos(cost)/2.0                // angle from z-axis to random vector, quaternoin wants 1/2 the angle
        
        var m = sint * sint                     // magnitude^2 of r perpendicular to z, need to normalize
        if m == 0 {                             // r=z or r=-z, so nothing happens in the xy plane
            rot = 0
        } else {                                // normalize the vector to rotate above to get z-axis to r
            m = sin(rot) * sint / sqrt(m)       //  for efficiency, also multiple by sin(rot)
        }
         // random rotation about z-axis
        let spin = Float.random(in: 0...(Float.pi))  // random amount of rotation about z-axis before rotating to random r, quaternion wants 1/2 angle
         
        // first rotate random amount around z-axis (last quqternion) and then rotate to random point on sphere (first quaternion)... we shouldn't have to normalize, but do it anyway.
        //self.simdOrientation = simd_mul(simd_quatf(ix: -m*sin(phi), iy: m*cos(phi), iz: 0, r: cos(rot)).normalized, simd_quatf(ix: 0, iy: 0, iz: sin(spin), r: cos(spin) ).normalized)
        return simd_mul(simd_quatf(ix: -m*sin(phi), iy: m*cos(phi), iz: 0, r: cos(rot)).normalized, simd_quatf(ix: 0, iy: 0, iz: sin(spin), r: cos(spin) ).normalized)
*/
        // self.simdOrientation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) // turn off random orientation
    }
    
    func randomVelocity(_ vOffset: SCNVector3) {
/*
        let m = Float(self.dieMass)             // impulse = delta p = m delta velocity
        let force = SCNVector3(x: (vOffset.x * (1 + Float.random(in: -0.1...0.1)))*m, y: (vOffset.y * (1 + Float.random(in: -0.1...0.1)))*m, z: (vOffset.z * (1 + Float.random(in: -0.1...0.1)))*m)
        self.physicsBody!.applyForce(force, asImpulse: true)
 */
        self.physicsBody!.velocity = SCNVector3(vOffset.x * (1 + Float.random(in: -0.1...0.1)),
                                                vOffset.y * (1 + Float.random(in: -0.1...0.1)),
                                                vOffset.z * (1 + Float.random(in: -0.1...0.1)))
    }
    
    func randomOmega(_ wOffset: Float) {

        // create random point on sphere (unit torque vector)
        let cost = Float.random(in: -1.0...1.0)
        let sint = sqrt(max(0, 1 - cost * cost))
        let phi = Float.random(in: 0.0...(2*Float.pi))
        let n = self.simdOrientation.act(simd_float3(cos(phi)*sint, sin(phi)*sint, cost))
/*
        let m = dieInertia  // +- moment of inertia, impluse = deta Iw = I delta w
        let torque = SCNVector4(x: n.x * m.x, y: n.y * m.y, z: n.z * m.z, w: (wOffset * (1 + Float.random(in: -0.3...0.3))) * Float(Int.random(in: 0...1)*2-1))
        self.physicsBody!.applyTorque(torque, asImpulse: true)
 */
        self.physicsBody!.angularVelocity = SCNVector4(n.x, n.y, n.z, wOffset * (1 + Float.random(in: -0.3...0.3)) * Float(Int.random(in: 0...1)*2-1))
    }

    override init() {
        
        super.init() // whatever SCNNode needs to do...
        
        // stuff all die share...
        self.categoryBitMask = 1
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) //SCNBox(width: size, height: size, length: size, chamferRadius: size*0.1))
        self.physicsBody!.restitution = dieRestitution //1.0
        self.physicsBody!.friction = dieFriction
        self.physicsBody!.categoryBitMask = 1
        self.physicsBody!.contactTestBitMask = 3
        self.castsShadow = true
        self.physicsBody!.usesDefaultMomentOfInertia = false
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
    /* everyone one needs these */
    func holdColor(pulse: Bool) {   // held dice appearance
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // dull, so the color shows up
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)
        if pulse { // ooh, do some eye candy
            if let diffuse = UIImage(named: "MyAssets/" + self.diffuseName + "DiceB") {self.geometry?.materials[0].diffuse.contents = diffuse}
            let ani1 = CABasicAnimation(keyPath: "geometry.materials[0].multiply.contents")
            ani1.fromValue = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ani1.toValue = #colorLiteral(red: 0.2745098039, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            ani1.duration = 0.4
            ani1.autoreverses = true
            ani1.repeatCount = .infinity
            self.addAnimation(ani1, forKey: "HOLDING")
        } else {  // not so much eye candy
            self.geometry?.materials[0].diffuse.contents = UIImage(named: "MyAssets/" + self.diffuseName + "DiceB")
            if let diffuse = UIImage(named: "MyAssets/" + self.diffuseName + "DiceB") {
                self.geometry?.materials[0].diffuse.contents = diffuse
            } else {
                self.geometry?.materials[0].multiply.contents = #colorLiteral(red: 0.2745098039, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            }
        }
    }
    func selectColor(pulse: Bool) { // selected dice appearance
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // dull, so the color shows up
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)
        if pulse { // ooh, do some eye candy
            if let diffuse = UIImage(named: "MyAssets/" + self.diffuseName + "DiceA") {self.geometry?.materials[0].diffuse.contents = diffuse}
            let ani1 = CABasicAnimation(keyPath: "geometry.materials[0].multiply.contents")
            ani1.fromValue = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ani1.toValue = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
            ani1.duration = 0.4
            ani1.autoreverses = true
            ani1.repeatCount = .infinity
            self.addAnimation(ani1, forKey: "HOLDING")
        } else {  // not so much eye candy
            if let diffuse = UIImage(named: "MyAssets/" + self.diffuseName + "DiceA") {
                self.geometry?.materials[0].diffuse.contents = diffuse
            } else {
                self.geometry?.materials[0].multiply.contents = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
            }
        }
    }
    func defaultColor(){  // default dice appearance
        self.removeAllAnimations()
        self.geometry?.materials[0].diffuse.contents = UIImage(named: "MyAssets/" + self.diffuseName + "Dice")
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // for more pretty
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        self.geometry?.materials[0].multiply.contents = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        //self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0.5176470588, green: 0.568627451, blue: 0.6470588235, alpha: 1)  // for more pretty
        //self.geometry?.materials[0].specular.contents = #colorLiteral(red: 1, green: 0.9529411765, blue: 0.8392156863, alpha: 1)
    }
    
    /* functions for D2 */
    func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        if simd_dot(up, self.presentation.simdOrientation.act(float3(0, 1, 0))) > 0 { // tails is up
            return 0
        } else {
            return 1
        }
    }

}


// now particular dice types. override above methods if needed

class Coin : Dice {  // coin, 2 sided die
    override func defaultColor(){  // default dice appearance
        super.defaultColor()
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) //#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    override func randomOmega(_ wOffset: Float) {
        
        let phi = Float.random(in: 0.0...(2*Float.pi))
        
        // torque is applied in world coordinates, so transform from local to world
        let n = self.simdOrientation.inverse.act(float3(cos(phi), 0, sin(phi)))
/*
        let m = dieInertia  // +- moment of inertia, impluse = delta Iw = I delta w
        let torque = SCNVector4(x: n.x * m.x, y: n.y * m.y, z: n.z * m.z, w: ( wOffset * (1 + Float.random(in: -0.3...0.3))))
        self.physicsBody!.applyTorque(torque, asImpulse: true)
 */
        self.physicsBody!.angularVelocity = SCNVector4(n.x, n.y, n.z, 2 * wOffset * (1 + Float.random(in: -0.3...0.3)) * Float(Int.random(in: 0...1)*2-1))
    }
    
    init(size: CGFloat) {
        
        super.init()
        
        //let size0 = size*sqrt(3.0)/2.0 //* 1.4
        let size0 = CGFloat(0.182/2.0)
        self.dieLength = 2 * size0
        //self.dieMass = CGFloat.pi * 0.15 * dieDensity * size0 * size0 * size0 //* 1000000
        self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 2, 1) * Float(size0 * size0 / 4 * self.dieMass)

        self.name = "die2"
        self.diffuseName = "coin"
        self.dieType = .dice2
        self.dieInR = size * 0.15 / 2
        self.dieCircumR = size0
        self.dieMidR = size0 / 2 //size * 0.15 * 2 //size0 / 4
        
        self.geometry = SCNScene(named: "art.scnassets/coin.scn")!.rootNode.childNodes[0].geometry
        var physCoin: SCNNode {
            
            let parent = SCNNode()
            //parent.addChildNode(SCNNode(geometry: SCNCylinder(radius: 1.05 * size0, height: size*0.05)))
            //parent.addChildNode(SCNNode(geometry: SCNTube(innerRadius: 0.5 * size0, outerRadius: 0.6 * size0, height: size*0.3)))
            parent.addChildNode(SCNNode(geometry: SCNCylinder(radius: size0, height: size*0.15)))
            //parent.addChildNode(SCNNode(geometry: SCNCylinder(radius: size0, height: size*0.25)))
            parent.addChildNode(SCNNode(geometry: SCNCylinder(radius: size0*1.02, height: size*0.02)))

            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physCoin, options: [SCNPhysicsShape.Option.keepAsCompound:true])
        //self.physicsBody!.physicsShape = SCNPhysicsShape(geometry: SCNCylinder(radius: size0, height: size*0.15), options: nil)
        let inertia = self.dieInertia
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y , inertia.z)
        //self.physicsBody!.rollingFriction = 0.5
        //self.physicsBody?.friction = 0.7
        self.physicsBody!.angularDamping = 0.5 //0.3 //0.7
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Tet: Dice {  // tetrahedron, 4 sided dice
    
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let norms: Array<float3> = [float3(0.46945852, 0.3441959, -0.8131041), float3(0.46944964, 0.34419796, 0.813108), float3(0, -1, 0), float3(-0.9388987, 0.34419358, 0)]
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        //        print(q.inverse.act(float3(0,-1,0)))
        var ic = 4
        var c = Float(0.0)
        for (i,n) in norms.enumerated() {                            // loop over three unit vectors
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            if a < c { c = a; ic=i+1}    // find most negative (is face down)?
        }
        return ic //should never get here
    }
    
    init(size: CGFloat) {
        
        super.init()
        
        let size0 = size * 1.3
        self.dieLength = size0
        self.dieMass = dieDensity * size0 * size0 * size0 / sqrt(72) //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size0 * size0 / 20)
        
        
        self.name = "die4"
        self.diffuseName = "tetra"
        self.dieType = .dice4
        let inertia = self.dieInertia
        
        self.geometry = SCNScene(named: "art.scnassets/tet.scn")!.rootNode.childNodes[0].geometry
        self.dieInR = 0.06740 //0.067401 // analytic: a/sqrt(24) = 0.2041241452 a
        self.dieCircumR = size0 * sqrt(3/8) * 1.15
        self.dieMidR = size0 / sqrt(8)
        
        var physNode: SCNNode {
            let parent = SCNNode()
            
            func create_tri(length: CGFloat, thickness: CGFloat) -> SCNGeometry {  // create equilateral triangle (flattened pyramid)
                return SCNPyramid(width: thickness, height: length*sqrt(3)/2, length: length)
            }
            
            func rot_trans(geometry: SCNGeometry, x: simd_float3, r: simd_quatf) -> SCNNode {  // rotate and move new node w/ this geometry
                let node = SCNNode(geometry: geometry)
                node.simdOrientation = r
                node.simdPosition = x
                return node
            }
            func trans(geometry: SCNGeometry, x: CGFloat, y: CGFloat, z: CGFloat) -> SCNNode { // move new node w/ this geometry
                let node = SCNNode(geometry: geometry)
                node.simdPosition = simd_float3(Float(x), Float(y), Float(z))
                return node
            }
            
            /* faces (as pyramids) */
            parent.addChildNode(rot_trans(geometry: create_tri(length: size0, thickness: size0*0.02),
                                          x: simd_float3(-Float(size0)/sqrt(12),-Float(size0)/sqrt(24), 0),
                                          r: simd_quatf(angle: Float.pi/2, axis: float3(0, 0, -1))))
            parent.addChildNode(rot_trans(geometry: create_tri(length: size0, thickness: size0*0.02),
                                          x: simd_float3(-Float(size0)/sqrt(12),-Float(size0)/sqrt(24), 0),
                                          r: simd_quatf(angle: Float.pi/2-acos(1/3), axis: float3(0, 0, -1))))
            parent.addChildNode(rot_trans(geometry: create_tri(length: size0, thickness: size0*0.02),
                                          x: simd_float3( Float(size0)/sqrt(48),-Float(size0)/sqrt(24),-Float(size0)/4),
                                          r: simd_mul(simd_quatf(angle: Float.pi/2-acos(1/3), axis: float3(sqrt(3/4), 0, 0.5)), simd_quatf(angle: Float.pi/3, axis: float3(0, 1, 0)))))
            parent.addChildNode(rot_trans(geometry: create_tri(length: size0, thickness: size0*0.02),
                                          x: simd_float3( Float(size0)/sqrt(48),-Float(size0)/sqrt(24), Float(size0)/4),
                                          r: simd_mul(simd_quatf(angle:-Float.pi/2+acos(1/3), axis: float3(sqrt(3/4), 0,-0.5)), simd_quatf(angle: Float.pi/3, axis: float3(0,-1, 0)))))
            
            /* corners (as spheres) */
            let d = size0*0.05 //0.05
            let r = size0//-d
            parent.addChildNode(trans(geometry: SCNSphere(radius: d), x:  0,          y:  r*sqrt(3/8), z:  0))
            parent.addChildNode(trans(geometry: SCNSphere(radius: d), x:  r/sqrt(3),  y: -r/sqrt(24),  z:  0))
            parent.addChildNode(trans(geometry: SCNSphere(radius: d), x: -r/sqrt(12), y: -r/sqrt(24),  z:  r/2))
            parent.addChildNode(trans(geometry: SCNSphere(radius: d), x: -r/sqrt(12), y: -r/sqrt(24),  z: -r/2))
            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physNode, options: [SCNPhysicsShape.Option.keepAsCompound:true]) //, SCNPhysicsShape.Option.collisionMargin:-1])
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y , inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Oct: Dice {  //octahedron, 8 sided die
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let a = Float(1/sqrt(3))
        let norms: Array<float3> = [float3(-a, a, a), float3(-a,-a,-a), float3(-a, a,-a), float3(-a,-a, a)]
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        var ic = 8
        var c = Float(0.0)
        for (i,n) in norms.enumerated() {            // loop over normal vectors
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            //if a > 0.81 { return i+1}         // is face up?
            //if a < -0.81 { return 8 - i}    // is face down?
            if abs(a) > abs(c) {c=a; ic=i}
        }
        return (c>0) ? ic+1 : 8-ic // 8 //should never get here
    }
    
    init(size: CGFloat) {
        super.init()
        
        self.dieLength = size * sqrt(2)
        let size0 = size //* 1.1 //2.2
        self.dieMass = dieDensity * size0 * size0 * size0 * sqrt(2)/3 //* 1000000
        //self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size0 * size0 / 10)
        
        
        let inertia = self.dieInertia
        self.name = "die8"
        self.diffuseName = "oct"
        self.dieType = .dice8
        self.geometry = SCNScene(named: "art.scnassets/oct.scn")!.rootNode.childNodes[0].geometry
        self.simdScale = simd_float3(1,1,1) * sqrt(2) * 0.1 / 1.85
        self.dieInR = 0.080825 // analytic: a / sqrt(2) =  0.7071067812 a = 0.7071067812 size0
        self.dieCircumR = size0 / sqrt(2) * 1.20
        self.dieMidR = size0 / 2
        
        var physOct: SCNNode {
            
            let parent = SCNNode()
            let pyrNode1 = SCNNode(geometry: SCNPyramid(width: size0, height: size0/sqrt(2), length: size0))
            pyrNode1.simdOrientation = simd_quatf(angle: Float.pi/4, axis: float3(0, 1, 0))
            let pyrNode2 = SCNNode(geometry: SCNPyramid(width: size0, height: size0/sqrt(2), length: size0))
            pyrNode2.simdOrientation = simd_mul(simd_quatf(angle: Float.pi, axis: float3(1, 0, 0)) ,simd_quatf(angle: Float.pi/4, axis: float3(0, 1, 0)))
            //let pyrNode2 = SCNNode(geometry: SCNPyramid(width: size0, height: -size0/sqrt(2), length: size0))
            //pyrNode2.simdOrientation = simd_quatf(angle: Float.pi/4, axis: float3(0, 1, 0))
            //let pyrNode2 = SCNNode(geometry: SCNPyramid(width: size0, height: size0/sqrt(2), length: size0))
            //pyrNode2.simdOrientation = simd_quatf(angle: Float.pi/4, axis: float3(0, 1, 0))
            //pyrNode2.simdScale = simd_float3(1, -1, 1)
            
            parent.addChildNode(pyrNode1)
            parent.addChildNode(pyrNode2)
            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physOct, options: [SCNPhysicsShape.Option.keepAsCompound:true])
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y, inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Dec: Dice {  // 10 sided die
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let norms: Array<float3> = [ float3( 0.42236373, 0.69545674, -0.58133376), float3(0.42236626, -0.6954555, 0.5813333),
                                     float3(-0.6834008, 0.6954546, 0.22204992), float3(-0, -0.6954547, -0.71856993),
                                     float3( 0, 0.6954537, 0.718571), float3(0.6833907, -0.6954652, -0.22204861),
                                     float3(-0.42237106, 0.6954607, -0.5813236), float3(-0.42236203, -0.6954633, 0.5813272),
                                     float3( 0.6832903, 0.6955215, 0.22218052), float3(-0.6833967, -0.69545895, -0.22204924)]
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        var ic = 10
        var c = Float(0.0)
        for (i,n) in norms.enumerated() {                            // loop over three unit vectors
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            //if a > 0.8 { return i+1}                // is face up?
            if a > c {c=a; ic=i+1}
        }
        return ic //should never get here
    }
    
    init(size: CGFloat) {
        super.init()
        
        self.dieLength = size * 1.2
        let size0 = size
        self.dieMass = dieDensity * size0 * size0 * size0 //* 1000000
        //self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size0 * size0 * 2 / 5)
        
        
        let inertia = self.dieInertia
        self.name = "die10"
        self.diffuseName = "dec"
        self.dieType = .dice10
        self.geometry = SCNScene(named: "art.scnassets/dec.scn")!.rootNode.childNodes[0].geometry
        self.simdScale = simd_float3(1,1,1) * 1.26 * 0.1 / 1.124
        self.dieInR = 0.0462955
        self.dieCircumR = size0 * 0.65
        self.dieMidR = self.dieInR //size0 * 0.66
        
        var physDeci: SCNNode {
            
            
            let r = size0 * 0.05 //0.3             // radius of corners, want big to avoid visual penetrationlet rho = size0 * 2 / (sqrt(5)-1) - r  // radius ico minus the corner radius
            let radius = size0 * 1.2 * 0.7 * 0.8 - r
            let height = size0 * 0.65 - r
            
            
            func trans(geometry: SCNGeometry, x: CGFloat, y: CGFloat, z: CGFloat) -> SCNNode { // move this new nodew/ this geometry
                let node = SCNNode(geometry: geometry)
                node.simdPosition = simd_float3(Float(x), Float(y), Float(z))
                return node
            }
            
            let parent = SCNNode()
            
            parent.addChildNode(trans(geometry: SCNSphere(radius: size0 * 0.46), x: 0, y: 0, z: 0)) // inscribed sphere
            parent.addChildNode(trans(geometry: SCNSphere(radius: 3*r), x: 0, y: height-3*r, z: 0))  // north pole
            parent.addChildNode(trans(geometry: SCNSphere(radius: 3*r), x: 0, y:-height+3*r, z: 0))  // south pole
            
            let y = sin(CGFloat.pi/25) * radius    // positive above/below equator
            let rho = cos(CGFloat.pi/25) * radius  // radius at this latitude
            for i in 0..<5 {  // all other vertices (10 more, 12 totoal)
                parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: rho*sin(CGFloat(2*i  )*CGFloat.pi/5), y: -y, z: rho*cos(CGFloat(2*i  )*CGFloat.pi/5)))
                parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: rho*sin(CGFloat(2*i+1)*CGFloat.pi/5), y:  y, z: rho*cos(CGFloat(2*i+1)*CGFloat.pi/5)))
            }
            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physDeci, options: [SCNPhysicsShape.Option.keepAsCompound:true])
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y, inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Dod: Dice {  // dodecahedron, 12 sided die
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let norms: Array<float3> = [float3( 0.85065114, 0,-0.5257305),  float3( 0.5257283, -0.85065234, 0),  float3( 0,-0.5257289,-0.850652),
                                    float3( 0.8506506, 0, 0.5257312),  float3( 0, 0.5257311, -0.8506508),  float3( 0.5257301, 0.85065144, 0)]
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        //print(q.inverse.act(float3(0, 1, 0)))
        var ic = 12
        var c = Float(0.0)
        for (i,n) in norms.enumerated() {                            // loop over three unit vectors
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            //if a > 0.8 { return i+1}         // is face up?
            //if a < -0.8 { return 12 - i}    // is face down?
            if abs(a) > abs(c) {c=a; ic=i}
        }
        return (c>0) ? ic+1 : 12-ic //12 //should never get here
    }
    
    init(size: CGFloat) {
        super.init()
        
        self.dieLength = size * 1.4
        let size0 = size * 0.5569 * 0.95
        self.dieMass = dieDensity * size0 * size0 * size0 * (15+7*sqrt(5)) / 4 //* 1000000
        //self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size0 * size0 * 3 / 5)
        
        
        let inertia = self.dieInertia
        self.name = "die12"
        self.diffuseName = "dod"
        self.dieType = .dice12
        self.geometry = SCNScene(named: "art.scnassets/dod.scn")!.rootNode.childNodes[0].geometry
        self.simdScale = simd_float3(1,1,1) * 0.1 * 1.4 / 1.81
        self.dieInR = 0.0599975  // analytic: a sqrt(5/2 + 11 sqrt(5) / 10) / 2 = a gr^2/2/sqrt(3-gr) = 1.1135163644 a = 0.5891114002 scale -> (0.5891114002 - balls) scale =
        self.dieCircumR = size0 * sqrt(3) * (1+sqrt(5)) / 4
        self.dieMidR = self.dieInR //size0 * (3+sqrt(5)) / 4
        
        var physDod: SCNNode {
            
            let gr = CGFloat((1+sqrt(5))/2) // golden ratio
            let r = size0 * 0.1 //0.15 //0.3             // radius of corners, want big to avoid visual penetration
            let radius = size0*sqrt(3)*gr/2 - r  // radius ico minus the corner radius
            
            func trans(geometry: SCNGeometry, x: CGFloat, y: CGFloat, z: CGFloat) -> SCNNode { // move this new nodew/ this geometry
                let node = SCNNode(geometry: geometry)
                node.simdPosition = simd_float3(Float(x), Float(y), Float(z))
                return node
            }
            
            let parent = SCNNode()
            
            parent.addChildNode(trans(geometry: SCNSphere(radius: size0*gr*gr/2/sqrt(3-gr)), x: 0, y: 0, z: 0)) // inscribed sphere
            
            let box = radius/sqrt(3)
            for ix in stride(from: -1, to: 2, by: 2) {
                for iy in stride(from: -1, to: 2, by: 2) {
                    for iz in stride(from: -1, to: 2, by: 2) {
                        parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: CGFloat(ix) * box, y: CGFloat(iy) * box, z: CGFloat(iz) * box)) // inscribed sphere
                    }
                    parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: CGFloat(ix) * box * gr, y: CGFloat(iy) * box / gr, z: 0))
                    parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: CGFloat(ix) * box / gr, y: 0, z: CGFloat(iy) * box * gr))
                    parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: 0, y: CGFloat(ix) * box * gr , z: CGFloat(iy) * box / gr))
                }
            }
            
            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physDod, options: [SCNPhysicsShape.Option.keepAsCompound:true])
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y, inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Ico: Dice {  // icosahedron, 20 sided die
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let norms: Array<float3> = [float3(-0.3035525, 0.18758848,-0.93416613),  float3(0.491112, 0.7946592, 0.3568272),     float3(0.60707474, -0.794645, 0),
                                    float3(-0.9822479, 0.18758817, 0),           float3(-0.3035398, 0.18758985, 0.93417007), float3(-0.1875706, 0.794651,-0.57736224),
                                    float3(0.18760364, -0.79464245, -0.5773632), float3(0.7946621, 0.18758227, -0.5773431),  float3(-0.4910938, -0.79467565, 0.35681581),
                                    float3(0.79466665, 0.18755808, 0.5773447)]
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        var ic = 20
        var c = Float(0.0)
        for (i,n) in norms.enumerated() {                            // loop over three unit vectors
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            //if a > 0.8 { return i+1}         // is face up?
            //if a < -0.8 { return 20 - i}    // is face down?
            if abs(a) > abs(c) {c=a; ic=i}
        }
        return (c>0) ? ic+1 : 20-ic //20 //should never get here
    }

    init(size: CGFloat) {
        super.init()
        
        self.dieLength = size * 1.9
        let size0 = size * 1.6 / 1.923                            
        self.dieMass = dieDensity * size0 * size0 * size0 * CGFloat((3+sqrt(5)) * 5 / 12) //* 1000000
        //self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size0 * size0 * 2 / 5)
        
        let inertia = self.dieInertia
        self.name = "die20"
        self.diffuseName = "ico"
        self.dieType = .dice20
        self.geometry = SCNScene(named: "art.scnassets/ico.scn")!.rootNode.childNodes[0].geometry
        self.simdScale = simd_float3(1,1,1) * 0.1 * 1.6 / 1.923
        self.dieInR = 0.0654445  // analytic: a sqrt(3) * (3+sqrt(5)) / 12 = a gr^2/2/sqrt(3) = 0.7557613141 a = 0.6288185661 a
        self.dieCircumR = size0 * sqrt(10 + 2*sqrt(5)) / 4
        self.dieMidR = self.dieInR //size0 * (1+sqrt(5)) / 4

        var physIco: SCNNode {
            
            let gr = CGFloat((1+sqrt(5))/2) // golden ratio
            let r = size0 * 0.15 //0.3             // radius of corners, want big to avoid visual penetration
            let radius = size0*sqrt(gr*sqrt(5))/2 - r  // radius ico minus the corner radius
            
            func trans(geometry: SCNGeometry, x: CGFloat, y: CGFloat, z: CGFloat) -> SCNNode { // move this new nodew/ this geometry
                let node = SCNNode(geometry: geometry)
                node.simdPosition = simd_float3(Float(x), Float(y), Float(z))
                return node
            }
            
            let parent = SCNNode()
            parent.addChildNode(trans(geometry: SCNSphere(radius: gr*gr*size0/sqrt(12)), x: 0, y: 0, z: 0)) // inscribed sphere
            parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: 0, y: radius, z: 0))  // north pole
            parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: 0, y:-radius, z: 0))  // south pole
            
            let y = sin(atan(1/2)) * radius    // positive above/below equator
            let rho = cos(atan(1/2)) * radius  // radius at this latitude
            for i in 0..<5 {  // all other vertices (10 more, 12 totoal)
                parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: rho*cos(CGFloat(2*i  )*CGFloat.pi/5), y:  y, z: rho*sin(CGFloat(2*i  )*CGFloat.pi/5)))
                parent.addChildNode(trans(geometry: SCNSphere(radius: r), x: rho*cos(CGFloat(2*i+1)*CGFloat.pi/5), y: -y, z: rho*sin(CGFloat(2*i+1)*CGFloat.pi/5)))
            }
            return parent
        }
        self.physicsBody!.physicsShape = SCNPhysicsShape(node: physIco, options: [SCNPhysicsShape.Option.keepAsCompound:true])
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y, inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}

class Cube : Dice { // cube, 6 sided die
    
    override func value(up: simd_float3) -> Int {            // return value of face showing in the 'up' direction
        let q = self.presentation.simdOrientation   // a quaternion from reference to final orientation
        var ic = 6
        var c = Float(0.0)
        for i in 1...3 {                            // loop over three unit vectors
            var n = simd_float3(0, 0, 0)
            n[(i+1) % 3] = 1                        // unit vector to rotate (first +z-axis, then +x-axis and then +y-axis, corresponding to 1, 2 and 3 faces
            let a = simd_dot(up, q.act(n))          // rotate with q and project onto 'up' (both are normalized so magnitude = cos of angle between them)
            //if a > 0.7071 { return i}         // is face up?
            //if a < -0.7071 { return 7 - i}    // is face down?
            if abs(a) > abs(c) {c=a; ic=i}
        }
        return (c>0) ? ic : 7-ic //6    //should never get here
    }
    override func defaultColor(){  // default dice appearance
        self.removeAllAnimations()
        self.geometry?.material(named: "diceBody")?.diffuse.contents = #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)
        self.geometry?.material(named: "diceDots")?.diffuse.contents = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0.5176470588, green: 0.568627451, blue: 0.6470588235, alpha: 1)  // for more pretty
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 1, green: 0.9529411765, blue: 0.8392156863, alpha: 1)
    }
    override func holdColor(pulse: Bool) {   // held dice appearance
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // dull, so the color shows up
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)
        if pulse { // ooh, do some eye candy
            let ani1 = CABasicAnimation(keyPath: "geometry.materials[0].diffuse.contents")
            ani1.fromValue = #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)
            ani1.toValue = #colorLiteral(red: 0.2745098039, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            ani1.duration = 0.4
            ani1.autoreverses = true
            ani1.repeatCount = .infinity
            self.addAnimation(ani1, forKey: "HOLDING")
            self.geometry?.material(named: "diceDots")?.diffuse.contents = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)//= #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)//
        } else {  // not so much eye candy
            self.geometry?.materials[0].diffuse.contents = #colorLiteral(red: 0.2745098039, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            self.geometry?.materials[1].diffuse.contents = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
        }
    }
    override func selectColor(pulse: Bool) {
        self.geometry?.materials[0].reflective.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // dull, so the color shows up
        self.geometry?.materials[0].specular.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)
        if pulse {  // pretty
            let ani1 = CABasicAnimation(keyPath: "geometry.materials[0].diffuse.contents")
            ani1.fromValue = #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)
            ani1.toValue = #colorLiteral(red: 0.7254901961, green: 0, blue: 0, alpha: 1)
            ani1.duration = 0.4
            ani1.autoreverses = true
            ani1.repeatCount = .infinity
            self.addAnimation(ani1, forKey: "SELECTING")
            let ani2 = CABasicAnimation(keyPath: "geometry.materials[1].diffuse.contents")
            ani2.fromValue = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
            ani2.toValue = #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)
            ani2.duration = 0.4
            ani2.autoreverses = true
            ani2.repeatCount = .infinity
            self.addAnimation(ani2, forKey: "selecting")
        } else {
            self.geometry?.materials[0].diffuse.contents = #colorLiteral(red: 0.7271999717, green: 0, blue: 0, alpha: 1)
            self.geometry?.materials[1].diffuse.contents = #colorLiteral(red: 0.7952535152, green: 0.7952535152, blue: 0.7952535152, alpha: 1)
        }
    }
    
    init(size: CGFloat) {
        
        super.init()
        
        self.dieLength = size*sqrt(3)
        self.dieMass = dieDensity * size * size * size //* 1000000
        self.dieInertia = simd_float3(1, 1, 1) * Float(self.dieMass * size * size / 6)
        self.dieInR = size / 2
        self.dieCircumR = size * sqrt(3) / 2
        self.dieMidR = size / sqrt(2)
        
        self.name = "die6"
        self.diffuseName = "cube"
        self.dieType = .dice6
        let inertia = self.dieInertia
        self.geometry = SCNScene(named: "art.scnassets/cube.scn")!.rootNode.childNodes[0].geometry
        self.physicsBody!.physicsShape = SCNPhysicsShape(geometry: SCNBox(width: size, height: size, length: size, chamferRadius: size*0.1), options: nil)
        self.physicsBody!.momentOfInertia = SCNVector3(inertia.x, inertia.y, inertia.z)
        self.physicsBody!.mass = self.dieMass
    }
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
}
