//
//  InAppNotification.swift
//  InAppNotification
//
//  Created by hiromi.sakurai.ts on 2020/09/06.
//  Copyright © 2020 hiromi.sakurai. All rights reserved.
//

import Foundation

struct InAppNotification {
    let message: String
    let onTap: (() -> Void)?
    let onClosed: (() -> Void)?
}
