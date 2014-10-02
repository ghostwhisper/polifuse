//
//  AppDelegate.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/24/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import UIKit
import GameKit

var playerID = ""
var scores = 0, level = 0, timeLeft = 0.00
var lastLevelStatus:Dictionary<String, String> = ["scores": "", "level": "", "timeLeft": ""]
var highScore : Dictionary<String, Int> = ["scores": 0, "level": 0]
var isAuthenticated:Bool = false
var localPlayer : GKLocalPlayer!
var gameCenterScore : GKScore!
var leaderBoard = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        GameViewController.setIfPause(true)
        GameViewController.pauseBGM()
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveLastLevelStatus()
        AppDelegate.updateScoreForGameCenterUser(highScore["scores"]!, currentLevel: highScore["level"]!)
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        GameViewController.setIsResume(true)
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        GameViewController.destroyTimer()
        saveLastLevelStatus()
        AppDelegate.updateScoreForGameCenterUser(highScore["scores"]!, currentLevel: highScore["level"]!)
    }
    
    class func updateHighScoreRecords(scores : Int, level : Int) {
        updateHighScoreRecords(scores, level: level, playerId: playerID);
    }
    
    class func updateHighScoreRecords(scores : Int, level : Int, playerId : String) {
        highScore = ["scores": scores, "level": level] as Dictionary
        playerID = playerId
    }
    
    class func saveLastLevelStatus(scores : Int, level : Int, timeLeft: Double){
        if (level > 0) {
            lastLevelStatus = ["scores": String(scores), "level": String(level), "timeLeft": NSString(format: "%.2f", timeLeft)]
            var result = lastLevelStatus as NSDictionary
            var data = NSKeyedArchiver.archivedDataWithRootObject(result)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: escapeUserId("lastLevel_\(playerID)"))
        }
    }
    
    func saveLastLevelStatus() {
        if (lastLevelStatus["level"]?.toInt() > 0) {
            var result = lastLevelStatus as NSDictionary
            var data = NSKeyedArchiver.archivedDataWithRootObject(result)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: AppDelegate.escapeUserId("lastLevel_\(playerID)"))
        }
    }
    
    class func loadLocalLastLevel() -> Dictionary<String, String>?{
        var existedRecord = Dictionary<String, String>()
        var result = NSUserDefaults.standardUserDefaults().dataForKey(escapeUserId("lastLevel_\(playerID)"))
        if (result != nil) {
            existedRecord = NSKeyedUnarchiver.unarchiveObjectWithData(result!) as Dictionary
        }
        return existedRecord
    }
    
    class func deleteLocalLastLevelRecord() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(escapeUserId("lastLevel_\(playerID)"))
    }
    
    class func setPlayerId(playerId: String) {
        playerID = playerId
    }
    
    class func getPlayerId() -> String {
        return playerID
    }
    
    class func syncLocalPlayerFromGC(player : GKLocalPlayer) {
        localPlayer = player
    }
    
    class func ifAuthenticated(authenticated:Bool){
        isAuthenticated = authenticated
    }
    
    class func setLeaderBoardID(leaderBoardId:String){
        leaderBoard = leaderBoardId
    }

    
    class func updateScoreForGameCenterUser(totalScore : Int, currentLevel : Int){
        updateHighScoreRecords(totalScore, level: currentLevel)
        if isAuthenticated {
            if (!leaderBoard.isEmpty) {
                gameCenterScore = GKScore(leaderboardIdentifier : leaderBoard, forPlayer : localPlayer.playerID)
                gameCenterScore.value = Int64(totalScore)
                GKScore.reportScores([gameCenterScore], withCompletionHandler: {(error) -> Void in
                    if error != nil {
                        self.updateHighScoreRecords(totalScore, level: currentLevel, playerId: localPlayer.playerID)
                    }
                })
            }
        }
    }
    
    class func escapeUserId(userID:String) -> String {
        let newUserID = userID.stringByReplacingOccurrencesOfString(":", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        return newUserID
    }
    
    
    class func updateLocalHighScore(totalScore:Int, level:Int){
        var playerID = AppDelegate.getPlayerId()
        
        var existedRecord = NSUserDefaults.standardUserDefaults().dataForKey(escapeUserId("highScore_\(playerID)"))
        if (existedRecord != nil) {
            var result = NSKeyedUnarchiver.unarchiveObjectWithData(existedRecord!) as NSDictionary
            var old_score = result["scores"]! as Int
            if (old_score < totalScore) {
                var highScore = ["scores": totalScore, "level": level] as NSDictionary
                var data = NSKeyedArchiver.archivedDataWithRootObject(highScore)
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: escapeUserId("highScore_\(playerID)"))
            }
        } else {
            var highScore = ["scores": totalScore, "level": level] as NSDictionary
            var data = NSKeyedArchiver.archivedDataWithRootObject(highScore)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: escapeUserId("highScore_\(playerID)"))
        }
    }

}

