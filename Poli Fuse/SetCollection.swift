//
//  SetCollection.swift
//  Poli Fuse
//
//  Created by Yuchen Li on 7/29/14.
//  Copyright (c) 2014 Yuchen Li. All rights reserved.
//

import Foundation

class SetCollection<T: Hashable>: Sequence, Printable {
    var dictionary = Dictionary<T, Bool>()  // private
    
    func addElement(newElement: T) {
        dictionary[newElement] = true
    }
    
    func removeElement(element: T) {
        dictionary[element] = nil
    }
    
    func containsElement(element: T) -> Bool {
        return dictionary[element] != nil
    }
    
    func allElements() -> Array<T>{
        return Array(dictionary.keys)
    }
    
    var count: Int {
    return dictionary.count
    }
    
    func unionSet(otherSet: SetCollection<T>) -> SetCollection<T> {
        var combined = SetCollection<T>()
        
        for obj in dictionary.keys {
            combined.dictionary[obj] = true
        }
        
        for obj in otherSet.dictionary.keys {
            combined.dictionary[obj] = true
        }
        
        return combined
    }
    
    func generate() -> IndexingGenerator<Array<T>> {
        return allElements().generate()
    }
    
    var description: String {
    return dictionary.description
    }
}
