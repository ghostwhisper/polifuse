//
//  MainMenuViewController.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 8/19/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//
import UIKit
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
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    @IBOutlet weak var highScoreImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // try to connect to game center
        gameCenterLoginWindow()
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
        logoAnimationController()
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
            button3.hidden = false
            hasSavedData = true
        }
        highScoreLabel.text = String(getTotalScore())

    }
    
    override func viewWillDisappear(animated: Bool) {
        logoImage.stopAnimating()
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
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
        var localPlayer = GKLocalPlayer.localPlayer()
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
                    if localPlayer.authenticated {
                        isAuthenticated = true
                        localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifier : String!, error : NSError!) -> Void in
                            if error != nil {
                                println(error.localizedDescription)
                            } else {
                                self.leaderboardIdentifier = leaderboardIdentifier
                            }
                        })
                        AppDelegate.setPlayerId(localPlayer.playerID)
                        AppDelegate.syncLocalPlayerFromGC(localPlayer)
                    } else {
                        isAuthenticated = false
                    }
                }
            }
        }
    }
    
    func logoAnimationController(){
        logoImage.userInteractionEnabled = false
        logoImage.animationImages = [UIImage(named: "Logo1"), UIImage(named: "Logo2")]
        logoImage.animationDuration = 1.0
        logoImage.startAnimating()
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
        var existedRecord = NSUserDefaults.standardUserDefaults().dataForKey("highScore_\(playerID)")
        if (existedRecord != nil) {
            var result = NSKeyedUnarchiver.unarchiveObjectWithData(existedRecord!) as NSDictionary
            scores = result["scores"]! as Int
        }
        return scores
    }
    
    func initializePlayButton(button: UIButton) -> UIButton {
        return setButtonBackgroundImage(button, image: playButtonImage, highlightImage :playButtonImageHighlighted)
    }
    func initializeResumeButton(button: UIButton) -> UIButton {
        return setButtonBackgroundImage(button, image: resumeButtonImage, highlightImage :resumeButtonImageHighlighted)
    }
    
    func initializeScoreButton(button: UIButton) -> UIButton {
        if (isAuthenticated == false) {
            button.hidden = true
        } else {
            button.hidden = false
        }
        return setButtonBackgroundImage(button, image: scoreboardButtonImage, highlightImage :scoreboardButtonImageHighlighted)
    }
    
}