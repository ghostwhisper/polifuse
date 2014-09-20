//
//  GameLevel.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/29/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import Foundation
let NumColumns = 9
var NumRows = 9

class GameLevel {
    private var polis = Array2D<Poli>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = SetCollection<Swap>()
    let targetScore: Int!
    let timeLeft: Float!
    var comboMultiplier: Int = 0  // private
    
    init(filename: String) {
        // 1
        if let dictionary = loadJsonFile(filename) {
            // 2
            if let tilesArray: AnyObject = dictionary["tiles"] {
                // 3
                if tilesArray is Array<Array<Int>> {
                    NumRows = tilesArray.count
                    polis = Array2D<Poli>(columns: NumColumns, rows: NumRows)
                    tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
                }
                for (row, rowArray) in enumerate(tilesArray as Array<Array<Int>>) {
                    // 4
                    let tileRow = NumRows - row - 1
                    // 5
                    for (column, value) in enumerate(rowArray) {
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                targetScore = (dictionary["targetScore"] as NSNumber).integerValue
                timeLeft = (dictionary["timeLeft"] as NSNumber).floatValue
            }
            
        }
    }
    
    func createInitialPolis() -> SetCollection<Poli> {
        var set = SetCollection<Poli>()
        
        // 1
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if (tiles[column, row] != nil){
                    
                    // 2
                    var poliType: PoliType
                    do {
                        poliType = PoliType.random()
                    }
                        while (column >= 2 &&
                            polis[column - 1, row]?.poliType == poliType &&
                            polis[column - 2, row]?.poliType == poliType)
                            || (row >= 2 &&
                                polis[column, row - 1]?.poliType == poliType &&
                                polis[column, row - 2]?.poliType == poliType)
                    
                    // 3
                    let poli = Poli(column: column, row: row, poliType: poliType)
                    polis[column, row] = poli
                    
                    // 4
                    set.addElement(poli)
                }
            }
        }
        return set
    }
    
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.one.column
        let rowA = swap.one.row
        let columnB = swap.theOther.column
        let rowB = swap.theOther.row
        
        polis[columnA, rowA] = swap.theOther
        swap.theOther.column = columnA
        swap.theOther.row = rowA
        
        polis[columnB, rowB] = swap.one
        swap.one.column = columnB
        swap.one.row = rowB
    }
    
    func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let poliType = polis[column, row]!.poliType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && polis[i, row]?.poliType == poliType;
            --i, ++horzLength { }
        for var i = column + 1; i < NumColumns && polis[i, row]?.poliType == poliType;
            ++i, ++horzLength { }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && polis[column, i]?.poliType == poliType;
            --i, ++vertLength { }
        for var i = row + 1; i < NumRows && polis[column, i]?.poliType == poliType;
            ++i, ++vertLength { }
        return vertLength >= 3
    }
    
    func getPoliFromPosition(column: Int, row: Int) -> Poli? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return polis[column, row]
    }
    
    func shuffle() -> SetCollection<Poli> {
        var set: SetCollection<Poli>
        do {
            set = createInitialPolis()
            detectPossibleSwaps()
            //println("possible swaps: \(possibleSwaps)")
        }
            while possibleSwaps.count == 0
        
        return set
    }
    
    func detectPossibleSwaps() {
        var set = SetCollection<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let poli = polis[column, row] {
                    // Is it possible to swap this poli with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a poli in this spot? If there is no tile, there is no cookie.
                        if let other = polis[column + 1, row] {
                            // Swap them
                            polis[column, row] = other
                            polis[column + 1, row] = poli
                            
                            // Is either poli now part of a chain?
                            if hasChainAtColumn(column + 1, row: row) ||
                                hasChainAtColumn(column, row: row) {
                                    set.addElement(Swap(one: poli, theOther: other))
                            }
                            
                            // Swap them back
                            polis[column, row] = poli
                            polis[column + 1, row] = other
                        }
                    }
                    
                    if row < NumRows - 1 {
                        if let other = polis[column, row + 1] {
                            polis[column, row] = other
                            polis[column, row + 1] = poli
                            
                            // Is either cookie now part of a chain?
                            if hasChainAtColumn(column, row: row + 1) ||
                                hasChainAtColumn(column, row: row) {
                                    set.addElement(Swap(one: poli, theOther: other))
                            }
                            
                            // Swap them back
                            polis[column, row] = poli
                            polis[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.containsElement(swap)
    }
    
    func detectHorizontalMatches() -> SetCollection<PoliChain> {
        // 1
        let set = SetCollection<PoliChain>()
        // 2
        for row in 0..<NumRows {
            for var column = 0; column < NumColumns - 2 ; {
                // 3
                if let poli = polis[column, row] {
                    let matchType = poli.poliType
                    // 4
                    if polis[column + 1, row]?.poliType == matchType &&
                        polis[column + 2, row]?.poliType == matchType {
                            // 5
                            let chain = PoliChain(chainType: .Horizontal)
                            do {
                                chain.add(polis[column, row]!)
                                ++column
                            }
                                while column < NumColumns && polis[column, row]?.poliType == matchType
                            
                            set.addElement(chain)
                            continue
                    }
                }
                // 6
                ++column
            }
        }
        return set
    }
    
    func detectVerticalMatches() -> SetCollection<PoliChain> {
        let set = SetCollection<PoliChain>()
        
        for column in 0..<NumColumns {
            for var row = 0; row < NumRows - 2; {
                if let cookie = polis[column, row] {
                    let matchType = cookie.poliType
                    
                    if polis[column, row + 1]?.poliType == matchType &&
                        polis[column, row + 2]?.poliType == matchType {
                            
                            let chain = PoliChain(chainType: .Vertical)
                            do {
                                chain.add(polis[column, row]!)
                                ++row
                            }
                                while row < NumRows && polis[column, row]?.poliType == matchType
                            
                            set.addElement(chain)
                            continue
                    }
                }
                ++row
            }
        }
        return set
    }
    
    
    func removeMatches() -> SetCollection<PoliChain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removePoliFromChain(horizontalChains)
        removePoliFromChain(verticalChains)
        
        calculateScores(horizontalChains)
        calculateScores(verticalChains)
        
        return horizontalChains.unionSet(verticalChains)
    }
    
    func removePoliFromChain(chains: SetCollection<PoliChain>) {
        for chain in chains {
            for poli in chain.poliList {
                polis[poli.column, poli.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Poli]] {
        var columns = [[Poli]]()
        // 1
        for column in 0..<NumColumns {
            var array = Array<Poli>()
            for row in 0..<NumRows {
                // 2
                if tiles[column, row] != nil && polis[column, row] == nil {
                    // 3
                    for lookup in (row + 1)..<NumRows {
                        if let poli = polis[column, lookup] {
                            // 4
                            polis[column, lookup] = nil
                            polis[column, row] = poli
                            poli.row = row
                            // 5
                            array.append(poli)
                            // 6
                            break
                        }
                    }
                }
            }
            // 7
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpPoli() -> [[Poli]] {
        var columns = [[Poli]]()
        var poliType: PoliType = .Unknown
        
        for column in 0..<NumColumns {
            var array = Array<Poli>()
            // 1
            for var row = NumRows - 1; row >= 0 && polis[column, row] == nil; --row {
                // 2
                if tiles[column, row] != nil {
                    // 3
                    var newPoliType: PoliType
                    do {
                        newPoliType = PoliType.random()
                    } while newPoliType == poliType
                    poliType = newPoliType
                    // 4
                    let poli = Poli(column: column, row: row, poliType: poliType)
                    polis[column, row] = poli
                    array.append(poli)
                }
            }
            // 5
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func calculateScores(chains: SetCollection<PoliChain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            ++comboMultiplier
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    func loadJsonFile(filename : String) -> Dictionary<String, AnyObject>?{
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        if path == nil {
            println("Could not find level file: \(filename)")
            return nil
        }
        
        var error: NSError?
        let data: NSData? = NSData(contentsOfFile: path!, options: NSDataReadingOptions(),
            error: &error)
        if data == nil {
            println("Could not load level file: \(filename), error: \(error!)")
            return nil
        }
        
        let dictionary: AnyObject! = NSJSONSerialization.JSONObjectWithData(data!,
            options: NSJSONReadingOptions(), error: &error)
        if dictionary == nil{
            println("Level file '\(filename)' is not valid JSON: \(error!)")
            return nil
        }
        
        return dictionary as? Dictionary<String, AnyObject>
    }
}