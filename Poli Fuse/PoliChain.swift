//
//  Chain.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/29/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import Foundation


class PoliChain: Hashable, Printable {
    var poliList = Array<Poli>()  // private
    var score: Int = 0
    
    enum ChainType: Printable {
        case Horizontal
        case Vertical
        
        var description: String {
        switch self {
        case .Horizontal: return "Horizontal"
        case .Vertical: return "Vertical"
            }
        }
    }
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func add(poli: Poli) {
        poliList.append(poli)
    }
    
    func firstOne() -> Poli {
        return poliList[0]
    }
    
    func lastOne() -> Poli {
        return poliList[poliList.count - 1]
    }
    
    var length: Int {
    return poliList.count
    }
    
    var description: String {
    return "type:\(chainType) cookies:\(poliList)"
    }
    
    var hashValue: Int {
    return reduce(poliList, 0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: PoliChain, rhs: PoliChain) -> Bool {
    return lhs.poliList == rhs.poliList
}