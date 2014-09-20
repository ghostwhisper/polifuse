//
//  MenuScene.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 8/19/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    override func didMoveToView(view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let background = SKSpriteNode(imageNamed: "MenuBackground")
        self.addChild(background)
        SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
//        
//        for touch: AnyObject in touches {
//            let location = touch.locationInNode(self)
//            
//            let sprite = SKSpriteNode(imageNamed:"Spaceship")
//            
//            sprite.xScale = 0.5
//            sprite.yScale = 0.5
//            sprite.position = location
//            
//            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
//            
//            sprite.runAction(SKAction.repeatActionForever(action))
//            
//            self.addChild(sprite)
//        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }

}
