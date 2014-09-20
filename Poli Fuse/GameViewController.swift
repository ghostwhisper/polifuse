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
//import iAd


var ifResumeGame = false
class GameViewController: UIViewController{// , ADBannerViewDelegate{
    let timerInterval: NSTimeInterval = 0.1
    
    var scene: GameScene!
    var level: GameLevel!
    var currentLevel: Int = 0
    var timer: NSTimer!
    var timeLeft: Double = 0.0
    var userCloseAds = false
    var score: Int = 0
    var isPaused: Bool = false
    var totalScore : Int = 0
    
    var backgroundMusic: AVAudioPlayer!
    
    @IBOutlet var targetLabel: UILabel!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet weak var highScore: UILabel!
    
    @IBOutlet weak var timerImage: UIImageView!
    @IBOutlet var scorePanel: UIImageView!
    @IBOutlet var middleUIViewPanel: UIImageView!
    @IBOutlet var resumeButton: UIImageView!
    @IBOutlet weak var highScoreImage: UIImageView!
    
    //@IBOutlet var iAdBanner: ADBannerView!
    
    
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var closeAdsBannerButton: UIButton!
    @IBOutlet var exitButton: UIButton!
    
    
    @IBAction func menuButtonPressed(AnyObject) {
        //        menuButton.showsTouchWhenHighlighted = true
        pauseGame()
    }
    
    @IBAction func closeAdsBannerButtonPressed(AnyObject) {
//        iAdBanner.hidden = true
        closeAdsBannerButton.hidden = true
        userCloseAds = true
    }
    
    @IBAction func exitButtonPressed(AnyObject) {
        gameOver()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //println(NSUserDefaults.standardUserDefaults().dictionaryRepresentation())
        //setup iAd
//        iAdBanner.delegate = self
//        iAdBanner.hidden = false
        closeAdsBannerButton.hidden = true
        
        // Configure the view.
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        
        exitButton.hidden = true
        highScore.hidden = true
        highScoreImage.hidden = true
        
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
        
        if (ifResumeGame) {
            let lastGameStatus:Dictionary<String, String> = AppDelegate.loadLocalLastLevel()!
            if (!lastGameStatus.isEmpty) {
                //lastLevelStatus = ["scores": scores, "level": level, "timeLeft": timeLeft]
                var result = NSString(string: lastGameStatus["level"]!)
                currentLevel = result.integerValue
                result = NSString(string: lastGameStatus["timeLeft"]!)
                timeLeft = result.doubleValue
                result = NSString(string: lastGameStatus["scores"]!)
                totalScore = result.integerValue
            }
            ifResumeGame = false
        }

        
        beginGame()
        
    }
    
    func beginGame() {
        var fileName: String
        fileName = NSString(format: "Level_%ld", currentLevel)
        let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType:"json")
        
        if (NSFileManager.defaultManager() .fileExistsAtPath(filePath!)) {
            level = GameLevel(filename: NSString(format: "Level_%ld", currentLevel))
        } else {
            showFinishAllLevels()
        }
        
        resetGame()
        
        shuffle()
        
        scene.level = level
        scene.addTiles()
        
        scene.swipeHandler = handleSwipe
        
        //shuffleButton.hidden = true
        
        timeLeft += Double(level.timeLeft)
        updateLabels()
        
        scene.animateGameSceneIn() {
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
        isPaused = false
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
        AppDelegate.updateLocalHighScore(totalScore, level: currentLevel)
    }
    
    func updateLabels() {
        targetLabel.text = NSString(format: "%ld", level.targetScore)
        scoreLabel.text = NSString(format: "%ld", score)
        levelLabel.text = NSString(format: "%ld",currentLevel + 1)
    }
    
    func updateGameInfo() {
        updateLabels()
        if self.score >= level.targetScore {
            levelUp()
        } else if timeLeft <= 0 {
            gameOver()
        }
    }
    
    func levelUp() {
        ++currentLevel
        AppDelegate.saveLastLevelStatus(totalScore, level: currentLevel, timeLeft : timeLeft)
        showLevelUp(){
            self.resetGame()
            self.beginGame()
        }
    }
    
    func gameOver() {
        showGameOver()
        isPaused = true
        timer = nil
        AppDelegate.updateScoreForGameCenterUser(totalScore, currentLevel: currentLevel)
        currentLevel = 0
        score = 0
        totalScore = 0
        timeLeft = 0
        userCloseAds = false
    }
    
    func showFinishAllLevels() {
        // need to finish
    }
    
    func resetGame() {
        hideMiddleImageViewPanel()
        timerLabel.hidden = false
        scorePanel.stopAnimating()
        scorePanel.image = UIImage(named: "FlyingPoli")
        isPaused = false
        score = 0
        level.resetComboMultiplier()
    }
    
    func showLevelUp(completion: () -> ()) {
        isPaused = true
        middleUIViewPanel.animationImages = [UIImage(named: "LevelComplete"), UIImage(named: "LevelComplete-Highlighted")]
        middleUIViewPanel.animationDuration = 0.5
        middleUIViewPanel.hidden = false
        middleUIViewPanel.startAnimating()
        scene.userInteractionEnabled = false
        //shuffleButton.hidden = true
        
        scene.animateGameSceneOut(completion)
    }
    
    func showGameOver() {
        highScoreImage.animationImages = [UIImage(named: "Highscore"), UIImage(named: "Highscore-Highlighted")]
        highScoreImage.animationDuration = 0.5
        highScoreImage.startAnimating()
        highScoreImage.hidden = false
        
        highScore.text = String(totalScore)
        highScore.hidden = false

        timerLabel.hidden = true
        exitButton.hidden = false
        scoreLabel.hidden = true
        
        middleUIViewPanel.image = UIImage(named: "GameOver")
        middleUIViewPanel.hidden = false
        //scene.userInteractionEnabled = false
        menuButton.userInteractionEnabled = false
        
        scene.animateGameSceneOut() {
            //self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "beginGame")
            //self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
        updateLabels()
    }
    
    
    func hideMiddleImageViewPanel() {
        //view.removeGestureRecognizer(tapGestureRecognizer)
        //tapGestureRecognizer = nil
        
        middleUIViewPanel.hidden = true
        scene.userInteractionEnabled = true
        middleUIViewPanel.stopAnimating()
    }
    
    
    
    func countDownTimer() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "updateTimerLabel", userInfo: nil, repeats: true)
        }
    }
    
    func pauseGame() {
        isPaused = true
        menuButton.userInteractionEnabled = false
        scene.animateGameSceneOut() {
            self.showPauseMenu()
        }
    }
    
    func showPauseMenu() {
        resumeButton.hidden = false
        resumeButton.userInteractionEnabled = true
        resumeButton.animationImages = [UIImage(named: "Resume"), UIImage(named: "Resume-Highlighted")]
        resumeButton.animationDuration = 0.7
        resumeButton.startAnimating()
        resumeButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "resumeGame"))
        
        exitButton.hidden = false
        
    }
    
    func resumeGame() {
        scene.userInteractionEnabled = true
        middleUIViewPanel.hidden = true
        resumeButton.hidden = true
        exitButton.hidden = true
        resumeButton.stopAnimating()
        scene.animateGameSceneIn() {
            self.isPaused = false
            self.menuButton.userInteractionEnabled = true
        }
    }
    
//    func showAdBanner() {
//        iAdBanner.hidden = false
//        if closeAdsBannerButton.hidden {
//            closeAdsBannerButton.hidden = false
//        }
//    }
//    
//    func hideAdBanner() {
//        iAdBanner.hidden = true
//        if !closeAdsBannerButton.hidden {
//            closeAdsBannerButton.hidden = true
//        }
//    }
    
    func updateTimerLabel () {
        if (!isPaused) {
            //            if iAdBanner.bannerViewActionInProgress {
            //                pauseGame()
            //                return
            //            }
            timeLeft = timeLeft - Double(timerInterval)
            //if timeLeft >= 10 {
            let minutes:Int = Int(timeLeft)/60
            let seconds:Int = Int(timeLeft) - minutes*60
            timerLabel.text = "\(twoDigitString(minutes)):\(twoDigitString(seconds))"
            //} else {
            //    timerLabel.text = NSString(format: "%.1f", timeLeft)
            //}
            if timeLeft <= 0.1 {
                isPaused = true
                timer.invalidate()
                timer = nil
                gameOver()
            }
        }
    }
    
//    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
//        if !(banner.hidden) {
//            banner.hidden = true
//        }
//    }
//    
//    func bannerViewDidLoadAd(banner: ADBannerView!) {
//        if banner.hidden{
//            banner.hidden = false
//        }
//    }
    
    class func setIsResume(resume : Bool) {
        ifResumeGame = resume
    }
    

    
    private func twoDigitString(number : Int) -> String {
        if (number == 0) {
            return "00"
        }
        if (number / 10 == 0) {
            return "0\(number)"
        }
        return String(number);
    }
}
