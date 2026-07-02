import UIKit
import GoogleMobileAds

final class ExpandedNativeAdView: NativeAdView {

  @IBOutlet weak var cardView: UIView!
  @IBOutlet weak var nativeMediaView: MediaView!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var headlineLabel: UILabel!
  @IBOutlet weak var advertiserLabel: UILabel!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var ctaButton: UIButton!
  @IBOutlet weak var adBadgeLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    configureStaticStyling()
    self.mediaView = nativeMediaView
    self.iconView = iconImageView
    self.headlineView = headlineLabel
    self.advertiserView = advertiserLabel
    self.bodyView = bodyLabel
    self.callToActionView = ctaButton
  }

  func bind(_ ad: NativeAd, isDark: Bool) {
    nativeAd = ad

    iconImageView.image     = ad.icon?.image
    headlineLabel.text      = ad.headline
    advertiserLabel.text    = ad.advertiser
    advertiserLabel.isHidden = (ad.advertiser ?? "").isEmpty
    bodyLabel.text          = ad.body
    bodyLabel.isHidden      = (ad.body ?? "").isEmpty
    ctaButton.setTitle(ad.callToAction ?? "Install", for: .normal)
    ctaButton.isHidden      = ad.callToAction == nil

    apply(isDark: isDark)
  }

  func apply(isDark: Bool) {
    let card: UIColor      = isDark ? DarkPalette.cardBg     : LightPalette.cardBg
    let headline: UIColor  = isDark ? DarkPalette.headline   : LightPalette.headline
    let body: UIColor      = isDark ? DarkPalette.body       : LightPalette.body
    let advertiser: UIColor = isDark ? DarkPalette.advertiser : LightPalette.advertiser
    let iconBg: UIColor    = isDark ? DarkPalette.iconBg     : LightPalette.iconBg
    let primary: UIColor   = isDark ? Brand.primaryDark      : Brand.primaryLight
    let onPrimary: UIColor = isDark ? Brand.onPrimaryDark    : Brand.onPrimaryLight

    cardView.backgroundColor      = card
    backgroundColor               = card
    iconImageView.backgroundColor = iconBg
    headlineLabel.textColor       = headline
    advertiserLabel.textColor     = advertiser
    bodyLabel.textColor           = body
    adBadgeLabel.backgroundColor  = Brand.blue
    adBadgeLabel.textColor        = .white
    ctaButton.backgroundColor     = primary
    ctaButton.setTitleColor(onPrimary, for: .normal)
  }

  private func configureStaticStyling() {
    iconImageView.contentMode = .scaleAspectFill
    iconImageView.clipsToBounds = true
    iconImageView.layer.cornerRadius = 10

    headlineLabel.font = .systemFont(ofSize: 14, weight: .bold)
    headlineLabel.numberOfLines = 1
    headlineLabel.lineBreakMode = .byTruncatingTail

    advertiserLabel.font = .systemFont(ofSize: 11)
    advertiserLabel.numberOfLines = 1
    advertiserLabel.lineBreakMode = .byTruncatingTail

    bodyLabel.font = .systemFont(ofSize: 12)
    bodyLabel.numberOfLines = 1
    bodyLabel.lineBreakMode = .byTruncatingTail

    adBadgeLabel.text = "Ad"
    adBadgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
    adBadgeLabel.layer.cornerRadius = 4
    adBadgeLabel.layer.masksToBounds = true
    adBadgeLabel.textAlignment = .center

    ctaButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    ctaButton.layer.cornerRadius = 16
    ctaButton.clipsToBounds = true
  }
}
