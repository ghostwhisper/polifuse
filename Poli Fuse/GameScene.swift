//
//  GameScene.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/24/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var level: GameLevel!
    
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let polisLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    
    var selectionSprite = SKSpriteNode()
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    
    var scoreLabelLocation:CGPoint!
    
    var swipeHandler: ((Swap) -> ())?
    
    let swapSound = SKAction.playSoundFileNamed("swipe.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("error1.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("GetPoint.wav", waitForCompletion: false)
    let fallingPoliSound = SKAction.playSoundFileNamed("addPoli.wav", waitForCompletion: false)
    let addPoliSound = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let multipleScoreSound = SKAction.playSoundFileNamed("cash-in.wav", waitForCompletion: false)
    
    override func didMoveToView(view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        
        addChild(gameLayer)
        
        gameLayer.hidden = true
        
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumColumns) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        gameLayer.addChild(cropLayer)
        
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        polisLayer.position = layerPosition
        cropLayer.addChild(polisLayer)
        
        
        swipeFromColumn = nil
        swipeFromRow = nil
        
        SKLabelNode(fontNamed: "AgencyFB-Bold")
    }
    
    func setScoreLabelLocation(point:CGPoint) {
        self.scoreLabelLocation = CGPoint(x:point.x - TileWidth * CGFloat(NumColumns) / 2, y:point.y - TileHeight * CGFloat(NumRows) / 2 - 140)
        println(self.scoreLabelLocation.y)
    }
    
    func addSpritesForPoli(polis: SetCollection<Poli>) {
        for poli in polis {
            let sprite = SKSpriteNode(imageNamed: poli.poliType.spriteName)
            sprite.position = pointForColumn(poli.column, row:poli.row)
            polisLayer.addChild(sprite)
            poli.sprite = sprite
            // Give each poli sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.runAction(
                SKAction.sequence([
                    SKAction.waitForDuration(0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeInWithDuration(0.25),
                        SKAction.scaleTo(1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*TileWidth + TileWidth/2,
            y: CGFloat(row)*TileHeight + TileHeight/2)
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
                return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let tile = level.tileAtColumn(column, row: row) {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for row in 0...NumRows {
            for column in 0...NumColumns {
                let topLeft     = ((column > 0) && (row < NumRows)
                    && level.tileAtColumn(column - 1, row: row) != nil)
                let bottomLeft  = ((column > 0) && (row > 0)
                    && level.tileAtColumn(column - 1, row: row - 1) != nil)
                let topRight    = ((column < NumColumns) && (row < NumRows)
                    && level.tileAtColumn(column, row: row) != nil)
                let bottomRight = ((column < NumColumns) && (row > 0)
                    && level.tileAtColumn(column, row: row - 1) != nil)
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by combining these four values.
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth/2
                    point.y -= TileHeight/2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // 1
        let touch = touches.anyObject() as UITouch
        let location = touch.locationInNode(polisLayer)
        // 2
        let (success, column, row) = convertPoint(location)
        if success {
            // 3
            if let poli = level.getPoliFromPosition(column, row: row) {
                // 4
                swipeFromColumn = column
                swipeFromRow = row
                
                showSelectionIndicatorForPoli(poli)
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        // 1
        if swipeFromColumn == nil { return }
        
        // 2
        let touch = touches.anyObject() as UITouch
        let location = touch.locationInNode(polisLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            
            // 3
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            
            // 4
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                // 5
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        touchesEnded(touches, withEvent: event)
    }
    
    func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
        // 1
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        // 2
        if toColumn < 0 || toColumn >= NumColumns { return }
        if toRow < 0 || toRow >= NumRows { return }
        // 3
        if let toPoli = level.getPoliFromPosition(toColumn, row: toRow) {
            if let fromPoli = level.getPoliFromPosition(swipeFromColumn!, row: swipeFromRow!) {
                // 4
                //                println("*** swapping \(fromPoli) with \(toPoli)")
                if let handler = swipeHandler {
                    let swap = Swap(one: fromPoli, theOther: toPoli)
                    handler(swap)
                }
            }
        }
    }
    
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.one.sprite!
        let spriteB = swap.theOther.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.3
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        runAction(swapSound)
    }
    
    func showSelectionIndicatorForPoli(poli: Poli) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = poli.sprite {
            let texture = SKTexture(imageNamed: poli.poliType.highlightedSpriteName)
            selectionSprite.size = texture.size()
            selectionSprite.runAction(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()]))
    }
    
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.one.sprite!
        let spriteB = swap.theOther.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: NSTimeInterval = 0.2
        
        let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
        moveB.timingMode = .EaseOut
        
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        runAction(invalidSwapSound)
    }
    
    func animateMatchedPolis(chains: SetCollection<PoliChain>, ifchain:Bool, completion: () -> ()) {
        for chain in chains {
            animateScoreForChain(chain)
            for poli in chain.poliList {
                if let sprite = poli.sprite {
                    if sprite.actionForKey("removing") == nil {
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.5)
                        scaleAction.timingMode = .EaseOut
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                            withKey:"removing")
                    }
                }
            }
        }
        if (ifchain) {
            runAction(multipleScoreSound)
        } else {
            runAction(matchSound)
        }
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingPolis(columns: Array<Array<Poli>>, completion: () -> ()) {
        // 1
        var longestDuration: NSTimeInterval = 0
        for array in columns {
            for (idx, poli) in enumerate(array) {
                let newPosition = pointForColumn(poli.column, row: poli.row)
                // 2
                let delay = 0.05 + 0.15*NSTimeInterval(idx)
                // 3
                let sprite = poli.sprite!
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
                // 4
                longestDuration = max(longestDuration, duration + delay)
                // 5
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([moveAction, fallingPoliSound])]))
            }
        }
        // 6
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewPolis(columns: Array<Array<Poli>>, completion: () -> ()) {
        // 1
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            // 2
            let startRow = array[0].row + 1
            
            for (idx, poli) in enumerate(array) {
                // 3
                let sprite = SKSpriteNode(imageNamed: poli.poliType.spriteName)
                sprite.position = pointForColumn(poli.column, row: startRow)
                polisLayer.addChild(sprite)
                poli.sprite = sprite
                // 4
                let delay = 0.1 + 0.1 * NSTimeInterval(array.count - idx - 1)
                // 5
                let duration = NSTimeInterval(startRow - poli.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                // 6
                let newPosition = pointForColumn(poli.column, row: poli.row)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.alpha = 0
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        SKAction.group([
                            SKAction.fadeInWithDuration(0.05),
                            moveAction,
                            addPoliSound])
                        ]))
            }
        }
        // 7
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateScoreForChain(chain: PoliChain) {
        // Figure out what the midpoint of the chain is.
        let firstSprite = chain.firstOne().sprite!
        let lastSprite = chain.lastOne().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2 - TileWidth * CGFloat(NumColumns) / 2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8 - TileHeight * CGFloat(NumRows) / 2)
        // Add a label for the score that slowly floats up.
        let scoreLabel = SKLabelNode(fontNamed: "AgencyFB-Bold")
        scoreLabel.fontSize = 16
        scoreLabel.text = NSString(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        scoreLabel.fontColor = UIColor.blackColor()
        gameLayer.addChild(scoreLabel)
        
        let moveUpAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.6)
        let moveAction = SKAction.moveTo(scoreLabelLocation, duration: 0.3)

        moveAction.timingMode = .EaseIn
        scoreLabel.runAction(SKAction.sequence([moveUpAction,moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameSceneOut(completion: () -> ()) {
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.5)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateGameSceneIn(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }
    
    func removeAllPoliSprites() {
        polisLayer.removeAllChildren()
        tilesLayer.removeAllChildren()
        maskLayer.removeAllChildren()
    }
    
    //    override func update(currentTime: CFTimeInterval) {
    //        /* Called before each frame is rendered */
    //    }
}