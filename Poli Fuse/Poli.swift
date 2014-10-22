//
//  Poli.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/29/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import Foundation

import SpriteKit

enum PoliType: Int, Printable {
    case Unknown = 0, Orange, Blue, Yellow, Red, Green
    var spriteName:String {
    let spriteNames = [
        "Orange",
        "Blue",
        "Yellow",
        "Red",
        "Green"
        ]
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
    let highlightedSpriteNames = ["Orange-Highlighted", "Blue-Highlighted", "Yellow-Highlighted", "Red-Highlighted", "Green-Highlighted" ]
        return highlightedSpriteNames[rawValue - 1]
    }
    
    static func random() -> PoliType {
        return PoliType(rawValue: Int(arc4random_uniform(5)) + 1)!
    }
    
    var description: String {
    return spriteName
    }
}

class Poli: Printable, Hashable {
    var column: Int
    var row: Int
    let poliType: PoliType
    var sprite: SKSpriteNode?
    
    init(column: Int, row:Int, poliType:PoliType) {
        self.column = column
        self.row = row
        self.poliType = poliType
    }
    
    var description: String {
    return "type:\(poliType) square:(\(column),\(row))"
    }
    
    var hashValue: Int {
    return row*10 + column
    }
    
}

func ==(lhs: Poli, rhs: Poli) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
