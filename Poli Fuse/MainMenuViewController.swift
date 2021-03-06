//
//  MainMenuViewController.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 8/19/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//
import UIKit
import AVFoundation
import SpriteKit
import GameKit

class MenuViewController: UIViewController, GKGameCenterControllerDelegate {
    var playButtonImage = UIImage(named: "PlayButton")
    var resumeButtonImage = UIImage(named: "Resume")
    var scoreboardButtonImage = UIImage(named: "ScoreButton")
    var playButtonImageHighlighted = UIImage(named: "PlayButton-Highlighted")
    var resumeButtonImageHighlighted = UIImage(named: "Resume-Highlighted")
    var scoreboardButtonImageHighlighted = UIImage(named: "ScoreButton-Highlighted")
    var hasSavedData = false
    var leaderboardIdentifier = ""
    var isAuthenticated = false
    var localPlayer : GKLocalPlayer!
    var startGameSoundEffect:AVAudioPlayer!
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    @IBOutlet weak var highScoreImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        gameCenterLoginWindow()
        // try to connect to game center
        // Configure the view.
        let skView = view as SKView
        let scene = MenuScene(size: skView.bounds.size)
        //            skView.showsFPS = true
        //            skView.showsNodeCount = true

        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = false
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        skView.presentScene(scene)
        
    }
    
    override func viewWillAppear(animated: Bool){
        super.viewWillAppear(animated)
        logoAnimationController()
        displayAllButtons()
        
        let url = NSBundle.mainBundle().URLForResource("startGame", withExtension: "mp3")
        let errorPoint = NSErrorPointer()
        startGameSoundEffect = AVAudioPlayer(contentsOfURL: url, error: errorPoint)
        startGameSoundEffect.numberOfLoops = 0
        startGameSoundEffect.prepareToPlay()
    }
    
    private func displayAllButtons(){
        let lastGameStatus:Dictionary<String, String> = AppDelegate.loadLocalLastLevel()!
        button3 = initializeScoreButton(button3)
        if (lastGameStatus.isEmpty) {
            button1 = initializePlayButton(button1)
            button2 = initializeScoreButton(button2)
            button3.hidden = true
            hasSavedData = false
        } else {
            button1 = initializeResumeButton(button1)
            button2 = initializePlayButton(button2)
            hasSavedData = true
        }
        highScoreLabel.text = String(getTotalScore())
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logoImage.stopAnimating()
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func startGame() {
        startGameSoundEffect.play()
        AppDelegate.deleteLocalLastLevelRecord()
        let view2 = self.storyboard?.instantiateViewControllerWithIdentifier("gameViewController") as GameViewController
        self.navigationController?.pushViewController(view2, animated: true)
    }
    
    func resumeGame() {
        let view2 = self.storyboard?.instantiateViewControllerWithIdentifier("gameViewController") as GameViewController
        self.navigationController?.pushViewController(view2, animated: true)
        GameViewController.setIsResume(true)
    }
    
    func showScoreBoard() {
        if (isAuthenticated != true) {
           gameCenterLoginWindow()
        } else {
            showLeaderboard()
        }
    }
    
    func gameCenterLoginWindow() {
        localPlayer = GKLocalPlayer.localPlayer()
        if (localPlayer.authenticated) {
            isAuthenticated = true
            AppDelegate.setPlayerId(localPlayer.playerID)
            AppDelegate.syncLocalPlayerFromGC(localPlayer)
        } else {
            localPlayer.authenticateHandler = {(viewController, error) -> Void in
                if viewController != nil {
                    self.presentViewController(viewController, animated: true, completion: nil)
                }
                else {
                    if self.localPlayer.authenticated {
                        self.isAuthenticated = true
                        self.localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifier : String!, error : NSError!) -> Void in
                            if error != nil {
                                println(error.localizedDescription)
                            } else {
                                self.leaderboardIdentifier = leaderboardIdentifier
                                AppDelegate.setLeaderBoardID(leaderboardIdentifier)
                            }
                        })
                        AppDelegate.ifAuthenticated(self.isAuthenticated)
                        AppDelegate.setPlayerId(self.localPlayer.playerID)
                        AppDelegate.syncLocalPlayerFromGC(self.localPlayer)
                    } else {
                        self.isAuthenticated = false
                    }
                    self.displayAllButtons()
                }
            }
        }
    }
    
    func logoAnimationController(){
        logoImage.userInteractionEnabled = false
        let image = UIImage.animatedImageWithImages([UIImage(named: "Logo1")!, UIImage(named: "Logo2")!], duration: 1.0)
        logoImage.image = image
    }
    
    func setButtonBackgroundImage(button: UIButton, image: UIImage, highlightImage : UIImage) -> UIButton {
        button.setBackgroundImage(image, forState: UIControlState.Normal)
        button.setBackgroundImage(highlightImage, forState: UIControlState.Highlighted)
        return button
    }
    @IBAction func button1TouchEventHandler(sender: UIButton) {
        if (hasSavedData == false){
            startGame()
        } else {
            resumeGame()
        }
        sender.highlighted = true
    }
    @IBAction func button2TouchEventHandler(sender: UIButton) {
        if (hasSavedData == false) {
            showScoreBoard()
        } else {
            startGame()
        }
    }
    @IBAction func button3TouchEventHandler(sender: UIButton) {
        showScoreBoard()
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!)
    {
        //code to dismiss your gameCenterViewController
        // for example:
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showLeaderboard()
    {
        var gcViewController: GKGameCenterViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        
        gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
        gcViewController.leaderboardIdentifier = leaderboardIdentifier
        self.presentViewController(gcViewController, animated: true, completion: nil)
    }
    
    func getTotalScore() -> Int{
        var playerID = AppDelegate.getPlayerId()
        var scores = 0
        var existedRecord = NSUserDefaults.standardUserDefaults().dataForKey(AppDelegate.escapeUserId("highScore_\(playerID)"))
        if (existedRecord != nil) {
            var result = NSKeyedUnarchiver.unarchiveObjectWithData(existedRecord!) as NSDictionary
            scores = result["scores"]! as Int
        }
        return scores
    }
    
    func initializePlayButton(button: UIButton) -> UIButton {
        button.hidden = false
        return setButtonBackgroundImage(button, image: playButtonImage!, highlightImage :playButtonImageHighlighted!)
    }
    func initializeResumeButton(button: UIButton) -> UIButton {
        return setButtonBackgroundImage(button, image: resumeButtonImage!, highlightImage :resumeButtonImageHighlighted!)
    }
    
    func initializeScoreButton(button: UIButton) -> UIButton {
        if (isAuthenticated == false) {
            button.hidden = true
        } else {
            button.hidden = false
        }
        return setButtonBackgroundImage(button, image: scoreboardButtonImage!, highlightImage :scoreboardButtonImageHighlighted!)
    }
    
}