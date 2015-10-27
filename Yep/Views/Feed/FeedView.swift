//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedView: UIView {

    var feed: ConversationFeed? {
        willSet {
            if let feed = newValue {
                configureWithFeed(feed)
            }
        }
    }

    var tapMediaAction: ((transitionView: UIView, imageURL: NSURL) -> Void)?

    static let foldHeight: CGFloat = 60

    weak var heightConstraint: NSLayoutConstraint?

    class func instanceFromNib() -> FeedView {
        return UINib(nibName: "FeedView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! FeedView
    }

    var foldProgress: CGFloat = 0 {
        willSet {
            if newValue >= 0 && newValue <= 1 {

                let normalHeight = self.normalHeight
                let attachmentURLsIsEmpty = attachmentURLs.isEmpty

                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in

                    self?.nicknameLabelCenterYConstraint.constant = -10 * newValue
                    self?.messageTextViewTopConstraint.constant = -25 * newValue + 4

                    if newValue == 1.0 {
                        self?.messageTextViewTrailingConstraint.constant = attachmentURLsIsEmpty ? 15 : (15 + 40 + 15)
                        //self?.messageLabel.numberOfLines = 1
                        self?.messageTextViewHeightConstraint.constant = 20
                        self?.messageTextView.scrollRangeToVisible(NSMakeRange(0, 1))
                    }

                    if newValue == 0.0 {
                        self?.messageTextViewTrailingConstraint.constant = 15
                        //self?.messageLabel.numberOfLines = 0
                        self?.calHeightOfMessageTextView()
                    }

                    self?.heightConstraint?.constant = FeedView.foldHeight + (normalHeight - FeedView.foldHeight) * (1 - newValue)

                    self?.layoutIfNeeded()

                    let foldingAlpha = (1 - newValue)
                    self?.distanceLabel.alpha = foldingAlpha
                    self?.mediaCollectionView.alpha = foldingAlpha
                    self?.timeLabel.alpha = foldingAlpha

                    self?.mediaView.alpha = newValue

                }, completion: nil)

                if newValue == 1.0 {
                    foldAction?()
                }

                if newValue == 0.0 {
                    unfoldAction?(self)
                }
            }
        }
    }

    var tapAvatarAction: (() -> Void)?
    var foldAction: (() -> Void)?
    var unfoldAction: (FeedView -> Void)?

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var mediaView: FeedMediaView!

    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    var attachmentURLs = [NSURL]() {
        didSet {
            mediaCollectionView.reloadData()
            mediaView.setImagesWithURLs(attachmentURLs)
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
        }()

    let feedMediaCellID = "FeedMediaCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageTextView.textColor = UIColor.darkGrayColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()

        messageTextView.scrollsToTop = false
        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        mediaView.alpha = 0

        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: "switchFold:")
        addGestureRecognizer(tap)
        tap.delegate = self

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)
    }

    func switchFold(sender: UITapGestureRecognizer) {

        if foldProgress == 1 {
            foldProgress = 0
        } else if foldProgress == 0 {
            foldProgress = 1
        }
    }

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }
    
    var normalHeight: CGFloat {

        guard let feed = feed else {
            return 60
        }

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)

        let height: CGFloat
        
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 80 + 15 + 17 + 15
        }

        return ceil(height)
    }

    var height: CGFloat {
        return bounds.height
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)
        messageTextViewHeightConstraint.constant = ceil(rect.height)
    }

    private func configureWithFeed(feed: ConversationFeed) {

        messageTextView.text = feed.body

        calHeightOfMessageTextView()

        let hasMedia = !feed.attachments.isEmpty
        timeLabelTopConstraint.constant = hasMedia ? (15 + 80 + 15) : 15
        mediaCollectionView.hidden = hasMedia ? false : true

        attachmentURLs = feed.attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })

        if let creator = feed.creator {
            let userAvatar = UserAvatar(userID: creator.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)

            nicknameLabel.text = creator.nickname
        }

        if let distance = feed.distance?.format(".1") {
            distanceLabel.text = "\(distance) km"
        }

        timeLabel.text = "\(NSDate(timeIntervalSince1970: feed.createdUnixTime).timeAgo)"
    }
}

// MARK: - UIGestureRecognizerDelegate

extension FeedView: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        let location = touch.locationInView(mediaCollectionView)

        if CGRectContainsPoint(mediaCollectionView.bounds, location) {
            return false
        }

        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension FeedView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachmentURLs.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaCellID, forIndexPath: indexPath) as! FeedMediaCell

        let imageURL = attachmentURLs[indexPath.item]

        //println("attachment imageURL: \(imageURL)")

        cell.configureWithImageURL(imageURL, bigger: (attachmentURLs.count == 1))

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionView = cell.imageView
        let imageURL = attachmentURLs[indexPath.item]
        tapMediaAction?(transitionView: transitionView, imageURL: imageURL)
    }
}

