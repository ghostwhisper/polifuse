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

var isPaused: Bool = false
var ifResumeGame = false
var timer:NSTimer = NSTimer()
let timerInterval: NSTimeInterval = 1 // don't modify this value unless you know what you are doing.
let soundEffectVolumn:Float = 0.9
let bgmVolumn:Float = 0.5
var backgroundMusic: AVAudioPlayer!
class GameViewController: UIViewController{// , ADBannerViewDelegate{

    var gameIsStarted = false
    var scene: GameScene!
    var level: GameLevel!
    var currentLevel: Int = 0

    var timeLeft: Double = 0.0
    var userCloseAds = false
    var score: Int = 0

    var totalScore : Int = 0
    
    var allGameSoundEffects = Dictionary<String,AVAudioPlayer>()
    var allBackgrounMusic:[AVAudioPlayer] = []
    
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
    @IBOutlet weak var scoreResultPage: UIImageView!
    @IBOutlet weak var scorePlaceHolderInScoreResultPage: UILabel!
    @IBOutlet weak var levelPlaceHolderInScoreResultPage: UILabel!
    
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
        terminateGameAndBackHomePage()
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
    
    override func viewWillDisappear(animated: Bool) {
        if (backgroundMusic.playing){
            backgroundMusic.stop()
        }
        if (getGameSound("hurray").playing){
            getGameSound("hurray").stop()
        }
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
        hideScoreResultPage()
        rotateLevelAndScorePlaceHolder()
        
        exitButton.hidden = true
        highScore.hidden = true
        highScoreImage.hidden = true
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        scene.setScoreLabelLocation(CGPoint(x: skView.bounds.size.width - scorePanel.center.x, y:skView.bounds.size.height - scorePanel.center.y))
        // Present the scene.
        skView.presentScene(scene)
        
    }
    
    private func showStartImageBan(){
        if (gameIsStarted == false) {
            scene.userInteractionEnabled = false
            middleUIViewPanel.hidden = false;
            middleUIViewPanel.animationImages = [UIImage(named: "Ready"), UIImage(named: "Go")]
            middleUIViewPanel.animationDuration = 3
            middleUIViewPanel.animationRepeatCount = 1
            middleUIViewPanel.startAnimating()
            gameIsStarted = true
        }
    }
    
    override func viewWillAppear(animated: Bool){
        super.viewWillAppear(animated)
        // Load and start background music.
        initBackgroundMusic("Track 1", formatExtension: "mp3")
        initBackgroundMusic("Track 12", formatExtension: "mp3")
        initBackgroundMusic("Track 13", formatExtension: "mp3")
    
        initAllGameSounds("GameOver", formatExtension: "mp3")
        initAllGameSounds("HeartBeat", formatExtension: "mp3")
        initAllGameSounds("levelUp", formatExtension: "wav")
        initAllGameSounds("hurray", formatExtension: "wav")
        
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
        
        backgroundMusic = getBackgroundMusicInIndex(Int(arc4random_uniform(UInt32(getCountOfAllBMG()))))
        
        beginGame()

    }
    
    private func initBackgroundMusic(fileName:String, formatExtension:String){
        let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: formatExtension)
        let errorPoint = NSErrorPointer()
        var bkmusic = AVAudioPlayer(contentsOfURL: url, error: errorPoint)
        bkmusic.numberOfLoops = 0
        bkmusic.volume = bgmVolumn
        bkmusic.prepareToPlay()
        allBackgrounMusic.append(bkmusic)
    }
    
    private func getBackgroundMusicInIndex(index:Int) -> AVAudioPlayer{
        return allBackgrounMusic[index]
    }
    
    private func getCountOfAllBMG() -> Int{
        return allBackgrounMusic.count
    }
    
    private func initAllGameSounds(fileName:String, formatExtension:String) {
        let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: formatExtension)
        let errorPoint = NSErrorPointer()
        var soundEffect = AVAudioPlayer(contentsOfURL: url, error: errorPoint)
        soundEffect.numberOfLoops = 0
        soundEffect.volume = soundEffectVolumn
        soundEffect.prepareToPlay()
        allGameSoundEffects.updateValue(soundEffect, forKey: fileName)
    }
    
    private func getGameSound(fileName:String) -> AVAudioPlayer {
        return allGameSoundEffects[fileName]!
    }
    
    func beginGame() {
        var fileName: String
        fileName = NSString(format: "Level_%ld", currentLevel)
        let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType:"json")
        
        if (filePath != nil && NSFileManager.defaultManager().fileExistsAtPath(filePath!)) {
            level = GameLevel(filename: NSString(format: "Level_%ld", currentLevel))
        } else {
            showFinishAllLevels()
            return
        }
        scene.cleanLayers()
        resetGame()
        
        shuffle()
        
        scene.level = level
        scene.addTiles()
        
        scene.swipeHandler = handleSwipe
        
        //shuffleButton.hidden = true
        
        timeLeft += Double(level.timeLeft)
        //timeLeft = Double(level.timeLeft)
        updateLabels()
        showTimerLabel()
        
        scene.animateGameSceneIn() {
            //self.shuffleButton.hidden = false
            self.showStartImageBan()
            self.countDownTimer()
        }
    }
    
    func shuffle() {
        scene.removeAllPoliSprites()
        let newPolis = level.shuffle()
        scene.addSpritesForPoli(newPolis)
    }
    
    class func setIfPause(ifPause:Bool) {
        isPaused = ifPause
    }
    
    class func pauseBGM(){
        backgroundMusic.pause()
    }
    
    func handleSwipe(swap: Swap) {
        GameViewController.setIfPause(false)
        view.userInteractionEnabled = false
        if level.isPossibleSwap(swap) {
            GameViewController.setIfPause(true)
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    var isChain = false;
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            isChain = false
            if (level.possibleSwaps.count == 0) {
                shuffle()
            }
            return
        }
        
        scene.animateMatchedPolis(chains, ifchain:isChain) {
            for chain in chains {
                self.score += chain.score
                self.totalScore += chain.score
            }
            self.isChain = true
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
        GameViewController.setIfPause(false)
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
            showGameOver()
            gameOver()
        }
    }
    
    func levelUp() {
        ++currentLevel
        AppDelegate.saveLastLevelStatus(totalScore, level: currentLevel, timeLeft : timeLeft)
        let heartBeatSoundEffect = getGameSound("HeartBeat")
        if (heartBeatSoundEffect.playing){
            heartBeatSoundEffect.stop()
        }
        getGameSound("levelUp").play()
        showLevelUp(){
            self.resetGame()
            self.beginGame()
        }
    }
    
    func gameOver() {
        backgroundMusic.stop()
        GameViewController.setIfPause(true)
        if (timer.valid) {
            timer.invalidate()
        }
        AppDelegate.updateScoreForGameCenterUser(totalScore, currentLevel: currentLevel)
        currentLevel = 0
        score = 0
        totalScore = 0
        timeLeft = 0
        userCloseAds = false
        AppDelegate.deleteLocalLastLevelRecord()
    }
    
    
    func showFinishAllLevels() {
        // need to finish
        let heartBeatSoundEffect = getGameSound("HeartBeat")
        if (heartBeatSoundEffect.playing){
            heartBeatSoundEffect.stop()
        }
        
        getGameSound("hurray").play()
        
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
            self.gameOver()
        }
    }
    
    func resetGame() {
        hideMiddleImageViewPanel()
        timerLabel.hidden = false
        scorePanel.stopAnimating()
        scorePanel.image = UIImage(named: "FlyingPoli")
        GameViewController.setIfPause(false)
        score = 0
        level.resetComboMultiplier()
    }
    
    func showLevelUp(completion: () -> ()) {
        GameViewController.setIfPause(true)
        middleUIViewPanel.animationImages = [UIImage(named: "LevelComplete"), UIImage(named: "LevelComplete-Highlighted")]
        middleUIViewPanel.animationDuration = 0.5
        middleUIViewPanel.hidden = false
        middleUIViewPanel.startAnimating()
        scene.userInteractionEnabled = false
        //shuffleButton.hidden = true
        
        scene.animateGameSceneOut(completion)
    }
    
    func showGameOver() {
        let heartBeatSoundEffect = getGameSound("HeartBeat")
        if (heartBeatSoundEffect.playing){
            heartBeatSoundEffect.stop()
        }
        let gameOverSound = getGameSound("GameOver")
        gameOverSound.play()
//        highScoreImage.animationImages = [UIImage(named: "Highscore"), UIImage(named: "Highscore-Highlighted")]
//        highScoreImage.animationDuration = 0.5
//        highScoreImage.startAnimating()
        highScoreImage.hidden = false
        
        highScore.text = String(totalScore)
        highScore.hidden = false

        timerLabel.hidden = true
//        exitButton.hidden = false
        scoreLabel.hidden = true
        
//        middleUIViewPanel.image = UIImage(named: "GameOver")
        middleUIViewPanel.hidden = false
        //scene.userInteractionEnabled = false
        menuButton.userInteractionEnabled = false
        
        scene.animateGameSceneOut() {
            //self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "beginGame")
            //self.view.addGestureRecognizer(self.tapGestureRecognizer)
            self.showScoreResultPage()
            self.initScoreResultPageImage()
        }
        updateLabels()
    }
    
    func showTimerLabel() {
        let minutes:Int = Int(timeLeft)/60
        let seconds:Int = Int(timeLeft) - minutes*60
        timerLabel.text = "\(twoDigitString(minutes)):\(twoDigitString(seconds))"
    }
    
    func hideMiddleImageViewPanel() {
        //view.removeGestureRecognizer(tapGestureRecognizer)
        //tapGestureRecognizer = nil
        
        middleUIViewPanel.hidden = true
        scene.userInteractionEnabled = true
        middleUIViewPanel.stopAnimating()
    }
    
    
    
    func countDownTimer() {
        if !timer.valid {
            timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "updateTimerLabel", userInfo: nil, repeats: true)
        }
    }
    
    class func destroyTimer() {
        if (timer.valid)    		{
            timer.invalidate()
        }
    }
    
    func pauseGame() {
        backgroundMusic.pause()
        let heartBeatSoundEffect = getGameSound("HeartBeat")
        if (heartBeatSoundEffect.playing){
            heartBeatSoundEffect.pause()
        }
        GameViewController.setIfPause(true)
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
        GameViewController.setIfPause(false)
        GameViewController.setIsResume(false)
        scene.userInteractionEnabled = true
        middleUIViewPanel.hidden = true
        resumeButton.hidden = true
        exitButton.hidden = true
        resumeButton.stopAnimating()
        scene.animateGameSceneIn() {
            self.menuButton.userInteractionEnabled = true
            self.countDownTimer()
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
        if (middleUIViewPanel.isAnimating() && gameIsStarted == true){
            return
        } else {
            middleUIViewPanel.hidden = true
            scene.userInteractionEnabled = true
        }
        if (!isPaused) {
            //            if iAdBanner.bannerViewActionInProgress {
            //                pauseGame()
            //                return
            //            }
            if (!backgroundMusic.playing){
                backgroundMusic = getBackgroundMusicInIndex(Int(arc4random_uniform(UInt32(getCountOfAllBMG()))))
                backgroundMusic.play()
            }
            timeLeft = timeLeft - Double(timerInterval)
            
            showTimerLabel()
            let heartBeatSoundEffect = getGameSound("HeartBeat")
            if (timeLeft < 10.1){
                backgroundMusic.volume = 0.1
                if (!heartBeatSoundEffect.playing){
                    heartBeatSoundEffect.play()
                }
                if (timerLabel.textColor == UIColor.redColor()) {
                    timerLabel.textColor = UIColor.blackColor()
                } else {
                    timerLabel.textColor = UIColor.redColor()
                }
            } else {
                if (heartBeatSoundEffect.playing){
                    heartBeatSoundEffect.pause()
                }
                backgroundMusic.volume = bgmVolumn
                timerLabel.textColor = UIColor.blackColor()
            }

            if timeLeft <= 0.1 {
                if (timer.valid) {
                    timer.invalidate()
                }
                showGameOver()
                gameOver()
            }
        } else if (isPaused && ifResumeGame) {
            pauseGame()
            GameViewController.destroyTimer()
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
        if (number <= 9) {
            return "0\(number)"
        }
        return String(number)
    }
    
    private func rotateLevelAndScorePlaceHolder() {
        scorePlaceHolderInScoreResultPage.transform = CGAffineTransformMakeRotation(-0.5)
        levelPlaceHolderInScoreResultPage.transform = CGAffineTransformMakeRotation(-0.5)
    }
    
    func showScoreResultPage(){
        scorePlaceHolderInScoreResultPage.hidden = false
        levelPlaceHolderInScoreResultPage.hidden = false
        scoreResultPage.hidden = false
    }
    
    func hideScoreResultPage(){
        scorePlaceHolderInScoreResultPage.hidden = true
        levelPlaceHolderInScoreResultPage.hidden = true
        scoreResultPage.hidden = true
    }
    
    func initScoreResultPageImage(){
        scoreResultPage.image = UIImage(named: "Background")
        scoreResultPage.userInteractionEnabled = true
        scoreResultPage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "terminateGameAndBackHomePage"))
    }
    
    func terminateGameAndBackHomePage(){
        gameOver()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}
