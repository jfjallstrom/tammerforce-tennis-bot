//
//  User+Equatable.swift
//  App
//
//  Created by Joose Fjällström on 17.12.2019.
//

import Foundation
import Telegrammer

extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
