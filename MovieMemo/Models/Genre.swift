//
//  Genre.swift
//  MovieMemo
//
//  Created by goutham pajjuru on 10/25/25.
//

import Foundation
import SwiftData

@Model
final class Genre {
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

