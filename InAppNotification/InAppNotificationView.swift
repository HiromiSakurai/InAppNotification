//
//  InAppNotificationView.swift
//  InAppNotification
//
//  Created by hiromi.sakurai.ts on 2020/09/06.
//  Copyright © 2020 hiromi.sakurai. All rights reserved.
//

import UIKit

protocol InAppNotificationShowable {
    func showInAppNotification(_ notification: InAppNotification)
}

extension InAppNotificationShowable where Self: UIViewController {
    func showInAppNotification(_ notification: InAppNotification) {
        InAppNotificationView(notification: notification).showBanner()
    }
}

class InAppNotificationView: UIView {
    // MARK:- View
    var targetWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .flatMap { $0 }?
            .windows.first
    }

    lazy var containerView: UIView = {
        let view = UIView()
        view.alpha = 0
        return view
    }()

    lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = notification.message

        label.textAlignment = .center
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        label.backgroundColor = .systemBlue
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let bannerHeight = CGFloat(60)
    let bannerMargin = CGFloat(12)

    // MARK:- Gesture
    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))

    var currentPositionY: CGFloat = 0

    // MARK:- Timer
    var bannerClosingTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }

    // MARK:- Other
    let notification: InAppNotification

    init(notification: InAppNotification) {
        self.notification = notification
        super.init(frame: .zero)
        addSubview(containerView)

        containerView.addSubview(messageLabel)
        let constraints = [
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            messageLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupBannerLayout() {
        guard let window = targetWindow else { return }

        let width = window.frame.width
        let height = bannerHeight + window.safeAreaInsets.top

        frame = CGRect(x: 0, y: 0, width: width, height: height)

        containerView.frame = CGRect(
            x: bannerMargin + window.safeAreaInsets.left,
            y: height - bannerHeight,
            width: width - ((bannerMargin * 2) + window.safeAreaInsets.left + window.safeAreaInsets.right),
            height: bannerHeight
        )
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }

    func showBanner() {
        setupBannerLayout()

        targetWindow?.addSubview(self)

        containerView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: -frame.height)

        UIView.animate(withDuration: 0.5, animations: {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.containerView.addGestureRecognizer(self.panGesture)
            self.containerView.addGestureRecognizer(self.tapGesture)
        })

        prepareForClosingBanner()
    }

    func closeBanner() {
        deallocate()

        UIView.animate(withDuration: 0.5, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = .init(translationX: 0, y: -self.frame.height)
        }, completion: { _ in
            self.notification.onClosed?()
            self.removeFromSuperview()
        })
    }

    func prepareForClosingBanner() {
        bannerClosingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.closeBanner()
        }
    }

    @objc
    func pan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            bannerClosingTimer = nil

        case .changed:
            let point = sender.translation(in: self)
            guard currentPositionY + point.y <= 0 else {
                return
            }
            currentPositionY += point.y
            containerView.transform = .init(translationX: 0, y: currentPositionY)
            sender.setTranslation(.zero, in: containerView)

        case .ended, .cancelled:
            if (abs(currentPositionY) > bannerHeight / 2) {
                closeBanner()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.containerView.transform = .identity
                }
                prepareForClosingBanner()
            }

        default:
            break
        }
    }

    @objc
    func tap(_ sender: UITapGestureRecognizer) {
        closeBanner()
        notification.onTap?()
    }

    // メモリリークを防ぐためにオブジェクトを解放する
    func deallocate() {
        containerView.removeGestureRecognizer(panGesture)
        containerView.removeGestureRecognizer(tapGesture)
        bannerClosingTimer = nil
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
