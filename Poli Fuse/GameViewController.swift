//
//  GameViewController.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/24/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import GameKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks")
        
        var sceneData = NSData.dataWithContentsOfFile(path, options: .DataReadingMappedIfSafe, error: nil)
        var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
        archiver.finishDecoding()
        return scene
    }
}

//class GameViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
//            // Configure the view.
//            let skView = self.view as SKView
//            skView.showsFPS = true
//            skView.showsNodeCount = true
//            
//            /* Sprite Kit applies additional optimizations to improve rendering performance */
//            skView.ignoresSiblingOrder = true
//            
//            /* Set the scale mode to scale to fit the window */
//            scene.scaleMode = .AspectFill
//            
//            skView.presentScene(scene)
//        }
//    }
//
//    override func shouldAutorotate() -> Bool {
//        return true
//    }
//
//    override func supportedInterfaceOrientations() -> Int {
//        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
//            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
//        } else {
//            return Int(UIInterfaceOrientationMask.All.toRaw())
//        }
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Release any cached data, images, etc that aren't in use.
//    }
//
//    override func prefersStatusBarHidden() -> Bool {
//        return true
//    }
//}



class GameViewController: UIViewController {
    var scene: GameScene!
    var level: GameLevel!
    var currentLevel: Int = 0
    var timer: NSTimer!
    var timeLeft: Double = 0.0
    let timerInterval: NSTimeInterval = 0.1
    var score: Int = 0
    var isPaused: Bool = false
    var totalScore : Int = 0
    
    var backgroundMusic: AVAudioPlayer!
    
    @IBOutlet var targetLabel: UILabel!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var middleUIViewPanel: UIImageView!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var scorePanel: UIImageView!
    @IBOutlet var highScoreLabel: UILabel!
    
    @IBAction func menuButtonPressed(AnyObject) {
        menuButton.showsTouchWhenHighlighted = true
        //isPaused = true
    }
//    @IBOutlet var shuffleButton: UIButton!
//    
//    @IBAction func shuffleButtonPressed(AnyObject) {
//        shuffle()
//        decrementMoves()
//    }
    
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        
        // Present the scene.
        skView.presentScene(scene)
        
        // Load and start background music.
        let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3")
        backgroundMusic = AVAudioPlayer(contentsOfURL: url, error: nil)
        backgroundMusic.numberOfLoops = -1
        //backgroundMusic.play()
        
        beginGame()
        
    }
    
    func beginGame() {
        
        var fileName: String
        fileName = NSString(format: "Level_%ld", currentLevel)
        let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType:"json")
        
        if (NSFileManager.defaultManager() .fileExistsAtPath(filePath)) {
            level = GameLevel(filename: NSString(format: "Level_%ld", currentLevel))
        } else {
            showGameOver()
        }
        
        shuffle()
        
        scene.level = level
        scene.addTiles()
        
        scene.swipeHandler = handleSwipe
        
        middleUIViewPanel.hidden = true
        
        //shuffleButton.hidden = true
        
        
        timeLeft += Double(level.timeLeft)
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        
        scene.animateBeginGame() {
            //self.shuffleButton.hidden = false
            self.countDownTimer()
        }
        
    }
    
    func shuffle() {
        scene.removeAllPoliSprites()
        let newPolis = level.shuffle()
        scene.addSpritesForPoli(newPolis)
    }
    
    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        if level.isPossibleSwap(swap) {
            isPaused = true
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        scene.animateMatchedPolis(chains) {
            for chain in chains {
                self.score += chain.score
                self.totalScore += chain.score
            }
            self.updateLabels()
            let columns = self.level.fillHoles()
            self.scene.animateFallingPolis(columns) {
                let columns = self.level.topUpPoli()
                self.scene.animateNewPolis(columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        isPaused = false
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        updateGameInfo()
    }
    
    func updateLabels() {
        targetLabel.text = NSString(format: "%ld", level.targetScore)
        scoreLabel.text = NSString(format: "%ld", score)
        levelLabel.text = NSString(format: "%ld",currentLevel + 1)
        highScoreLabel.text = NSString(format: "%ld", totalScore)
    }
    
    func updateGameInfo() {
        updateLabels()
        if self.score >= level.targetScore {
            levelUp()
            beginGame()
        } else if timeLeft <= 0 {
            gameOver()
        }
    }
    
    func levelUp() {
        ++currentLevel
        score = 0
        showLevelUp()
    }
    
    func gameOver() {
        totalScore += score
        currentLevel = 0
        showGameOver()
    }
    
    func showLevelUp() {
        isPaused = true
        middleUIViewPanel.animationImages = [UIImage(named: "LevelComplete"), UIImage(named: "LevelComplete-Highlighted")]
        middleUIViewPanel.animationDuration = 0.5
        middleUIViewPanel.hidden = false
        middleUIViewPanel.startAnimating()
        scene.userInteractionEnabled = false
        //shuffleButton.hidden = true
        
        scene.animateGameOver() {
            self.hideMiddleImageViewPanel()
            //self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideMiddleImageViewPanel")
            //self.view.addGestureRecognizer(self.tapGestureRecognizer)
            self.isPaused = false
            self.middleUIViewPanel.stopAnimating()
        }
    }
    
    func showGameOver() {
        scorePanel.animationImages = [UIImage(named: "Highscore"), UIImage(named: "Highscore-Highlighted")]
        scorePanel.animationDuration = 0.5
        scorePanel.startAnimating()
        scoreLabel.text = NSString(format: "%ld", totalScore)
        timerLabel.hidden = true
        middleUIViewPanel.image = UIImage(named: "GameOver")
        middleUIViewPanel.hidden = false
        scene.userInteractionEnabled = false
        //shuffleButton.hidden = true
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    func hideMiddleImageViewPanel() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        middleUIViewPanel.hidden = true
        scene.userInteractionEnabled = true
    }
    
    func authenticateLocalPlayer() {
        var localPlayer = GKLocalPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if viewController {
                self.presentViewController(viewController, animated: true, completion: nil)
            }
        }
    }
    
    func countDownTimer() {
        if !timer {
         timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "updateTimerLabel", userInfo: nil, repeats: true)
        }
    }

    func updateTimerLabel () {
        if (!isPaused) {
            timeLeft = timeLeft - Double(timerInterval)
            if timeLeft >= 10 {
                timerLabel.text = NSString(format: "%ld", Int(timeLeft))
            } else {
                timerLabel.text = NSString(format: "%.1f", timeLeft)
            }
            if timeLeft <= 0 {
                isPaused = true
                timer.invalidate()
                gameOver()
            }
        }
    }
    
}
