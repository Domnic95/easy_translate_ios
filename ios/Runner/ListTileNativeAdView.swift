import UIKit
import GoogleMobileAds

final class ListTileNativeAdView: NativeAdView {

  @IBOutlet weak var cardView: UIView!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var adBadgeLabel: UILabel!
  @IBOutlet weak var headlineLabel: UILabel!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var ctaButton: UIButton!
  @IBOutlet weak var nativeMediaView: MediaView!

  private let ctaGradient = CAGradientLayer()

  override func awakeFromNib() {
    super.awakeFromNib()
    configureStaticStyling()
    self.iconView = iconImageView
    self.headlineView = headlineLabel
    self.bodyView = bodyLabel
    self.callToActionView = ctaButton
    self.mediaView = nativeMediaView
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    ctaGradient.frame = ctaButton.bounds
  }

  func bind(_ ad: NativeAd, isDark: Bool) {
    nativeAd = ad

    iconImageView.image = ad.icon?.image
    headlineLabel.text  = ad.headline
    bodyLabel.text      = ad.body
    bodyLabel.isHidden  = (ad.body ?? "").isEmpty
    let rawCta = (ad.callToAction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let cta = rawCta.isEmpty ? "Install" : rawCta
    setCtaTitle(cta)
    ctaButton.isHidden = false

    apply(isDark: isDark)
  }

  func apply(isDark: Bool) {
    let card: UIColor      = isDark ? DarkPalette.cardBg     : LightPalette.cardBg
    let headline: UIColor  = isDark ? DarkPalette.headline   : LightPalette.headline
    let body: UIColor      = isDark ? DarkPalette.body       : LightPalette.body
    let iconBg: UIColor    = isDark ? DarkPalette.iconBg     : LightPalette.iconBg

    cardView.backgroundColor      = card
    backgroundColor               = card
    iconImageView.backgroundColor = iconBg
    headlineLabel.textColor       = headline
    bodyLabel.textColor           = body
    adBadgeLabel.backgroundColor  = Brand.blue
    adBadgeLabel.textColor        = .white
    ctaButton.setTitleColor(.white, for: .normal)
  }

  private func setCtaTitle(_ text: String) {
    let font = UIFont.systemFont(ofSize: 12, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.white,
    ]
    ctaButton.setTitle(nil, for: .normal)
    ctaButton.setAttributedTitle(
      NSAttributedString(string: text, attributes: attrs),
      for: .normal
    )
    ctaButton.titleLabel?.text = text
    ctaButton.titleLabel?.textColor = .white
    ctaButton.titleLabel?.font = font
    ctaButton.titleLabel?.isHidden = false
    ctaButton.titleLabel?.alpha = 1
  }

  private func configureStaticStyling() {
    iconImageView.contentMode = .scaleAspectFill
    iconImageView.clipsToBounds = true
    iconImageView.layer.cornerRadius = 10

    adBadgeLabel.text = "Ad"
    adBadgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
    adBadgeLabel.layer.cornerRadius = 4
    adBadgeLabel.layer.masksToBounds = true
    adBadgeLabel.textAlignment = .center

    headlineLabel.font = .systemFont(ofSize: 13, weight: .bold)
    headlineLabel.numberOfLines = 1
    headlineLabel.lineBreakMode = .byTruncatingTail
    bodyLabel.font = .systemFont(ofSize: 11)
    bodyLabel.numberOfLines = 1
    bodyLabel.lineBreakMode = .byTruncatingTail

    ctaButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
    ctaButton.layer.cornerRadius = 17
    ctaButton.clipsToBounds = true
    if #available(iOS 15.0, *) {
      ctaButton.configuration = nil
    }
    ctaButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

    ctaGradient.colors = [Brand.blue.cgColor, Brand.violet.cgColor]
    ctaGradient.startPoint = CGPoint(x: 0, y: 0.5)
    ctaGradient.endPoint   = CGPoint(x: 1, y: 0.5)
    ctaButton.layer.insertSublayer(ctaGradient, at: 0)

    nativeMediaView?.alpha = 0
  }
}
