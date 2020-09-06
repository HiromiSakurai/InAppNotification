//
//  ViewController.swift
//  InAppNotification
//
//  Created by hiromi.sakurai on 2020/09/06.
//  Copyright © 2020 hiromi.sakurai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, InAppNotificationShowable {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let notification = InAppNotification(
                message: "This is In App Notification!!",
                onTap: { print("on tapped!!") },
                onClosed: { print("on closed!!") }
            )
            self.showInAppNotification(notification)
        }
    }
}
