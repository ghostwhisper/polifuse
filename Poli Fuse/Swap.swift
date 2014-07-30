//
//  Swap.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/29/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import Foundation

class Swap: Printable, Hashable {
    var one: Poli
    var theOther: Poli
    
    init(one: Poli, theOther: Poli) {
        self.one = one
        self.theOther = theOther
    }
    
    var description: String {
    return "swap \(one) with \(theOther)"
    }
    
    var hashValue: Int {
    return one.hashValue ^ theOther.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.one == rhs.one && lhs.theOther == rhs.theOther) ||
        (lhs.theOther == rhs.one && lhs.one == rhs.theOther)
}