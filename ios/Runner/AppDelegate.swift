import Flutter
import UIKit
import CoreMotion
import GoogleMobileAds
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let motionManager = CMMotionManager()
  private var lastValidOrientation = "portraitUp"

  private func gravityOrientation() -> String {
    guard let g = motionManager.deviceMotion?.gravity else {
      return lastValidOrientation
    }
    let horizontal = (g.x * g.x + g.y * g.y).squareRoot()
    if horizontal < 0.3 {
      return lastValidOrientation
    }
    let orientation: String
    if abs(g.x) >= abs(g.y) {
      orientation = g.x < 0 ? "landscapeLeft" : "landscapeRight"
    } else {
      orientation = g.y < 0 ? "portraitUp" : "portraitDown"
    }
    lastValidOrientation = orientation
    return orientation
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "expandedNativeAd",
      nativeAdFactory: ExpandedNativeAdFactory()
    )

    let channel = FlutterMethodChannel(
      name: "easy_translate/device_orientation",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "start":
        if self.motionManager.isDeviceMotionAvailable,
           !self.motionManager.isDeviceMotionActive {
          self.motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
          self.motionManager.startDeviceMotionUpdates()
        }
        result(nil)
      case "stop":
        if self.motionManager.isDeviceMotionActive {
          self.motionManager.stopDeviceMotionUpdates()
        }
        result(nil)
      case "get":
        result(self.gravityOrientation())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private enum Brand {
  static let blue   = UIColor(red: 0x3B/255.0, green: 0x82/255.0, blue: 0xF6/255.0, alpha: 1.0)
  static let violet = UIColor(red: 0x8B/255.0, green: 0x5C/255.0, blue: 0xF6/255.0, alpha: 1.0)

  static let primaryLight    = UIColor(red: 0x25/255.0, green: 0x63/255.0, blue: 0xEB/255.0, alpha: 1.0)
  static let primaryDark     = UIColor(red: 0x60/255.0, green: 0xA5/255.0, blue: 0xFA/255.0, alpha: 1.0)
  static let onPrimaryLight  = UIColor.white
  static let onPrimaryDark   = UIColor(red: 0x07/255.0, green: 0x10/255.0, blue: 0x29/255.0, alpha: 1.0)
}

private enum LightPalette {
  static let cardBg     = UIColor.white
  static let headline   = UIColor(red: 0x0F/255.0, green: 0x17/255.0, blue: 0x2A/255.0, alpha: 1.0)
  static let body       = UIColor(red: 0x47/255.0, green: 0x55/255.0, blue: 0x69/255.0, alpha: 1.0)
  static let advertiser = UIColor(red: 0x94/255.0, green: 0xA3/255.0, blue: 0xB8/255.0, alpha: 1.0)
  static let iconBg     = UIColor(red: 0xEE/255.0, green: 0xF2/255.0, blue: 0xFF/255.0, alpha: 1.0)
}

private enum DarkPalette {
  static let cardBg     = UIColor(red: 0x11/255.0, green: 0x1A/255.0, blue: 0x33/255.0, alpha: 1.0)
  static let headline   = UIColor(red: 0xE2/255.0, green: 0xE8/255.0, blue: 0xF0/255.0, alpha: 1.0)
  static let body       = UIColor(red: 0xB6/255.0, green: 0xBF/255.0, blue: 0xCB/255.0, alpha: 1.0)
  static let advertiser = UIColor(red: 0x94/255.0, green: 0xA3/255.0, blue: 0xB8/255.0, alpha: 1.0)
  static let iconBg     = UIColor(red: 0x1B/255.0, green: 0x25/255.0, blue: 0x47/255.0, alpha: 1.0)
}

private final class PaddedLabel: UILabel {
  private let inset = UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: inset))
  }
  override var intrinsicContentSize: CGSize {
    let s = super.intrinsicContentSize
    return CGSize(
      width:  s.width  + inset.left + inset.right,
      height: s.height + inset.top  + inset.bottom
    )
  }
}

private final class GradientPillButton: UIButton {
  private let gradient = CAGradientLayer()
  override init(frame: CGRect) {
    super.init(frame: frame); setup()
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder); setup()
  }
  private func setup() {
    gradient.colors = [Brand.blue.cgColor, Brand.violet.cgColor]
    gradient.startPoint = CGPoint(x: 0, y: 0.5)
    gradient.endPoint   = CGPoint(x: 1, y: 0.5)
    layer.insertSublayer(gradient, at: 0)
    setTitleColor(.white, for: .normal)
    titleLabel?.textAlignment = .center
    clipsToBounds = true
  }
  override func layoutSubviews() {
    super.layoutSubviews()
    gradient.frame = bounds
  }
}

final class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let isDark = (customOptions?["isDark"] as? Bool) ?? false
    let pal: (cardBg: UIColor, head: UIColor, body: UIColor, iconBg: UIColor) =
      isDark
        ? (DarkPalette.cardBg,  DarkPalette.headline,  DarkPalette.body,  DarkPalette.iconBg)
        : (LightPalette.cardBg, LightPalette.headline, LightPalette.body, LightPalette.iconBg)

    let adView = NativeAdView()
    adView.backgroundColor = pal.cardBg

    let icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    icon.clipsToBounds = true
    icon.layer.cornerRadius = 10
    icon.backgroundColor = pal.iconBg
    icon.image = nativeAd.icon?.image
    adView.iconView = icon

    let badge = PaddedLabel()
    badge.translatesAutoresizingMaskIntoConstraints = false
    badge.text = "Ad"
    badge.textColor = .white
    badge.font = .systemFont(ofSize: 10, weight: .bold)
    badge.backgroundColor = Brand.blue
    badge.layer.cornerRadius = 4
    badge.clipsToBounds = true
    badge.textAlignment = .center
    badge.accessibilityLabel = "Advertisement"
    badge.isAccessibilityElement = true
    badge.setContentHuggingPriority(.required, for: .horizontal)
    badge.setContentCompressionResistancePriority(.required, for: .horizontal)

    let headline = UILabel()
    headline.translatesAutoresizingMaskIntoConstraints = false
    headline.text = nativeAd.headline
    headline.textColor = pal.head
    headline.font = .systemFont(ofSize: 13, weight: .bold)
    headline.numberOfLines = 1
    headline.lineBreakMode = .byTruncatingTail
    headline.setContentHuggingPriority(.defaultLow, for: .horizontal)
    headline.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    adView.headlineView = headline

    let body = UILabel()
    body.translatesAutoresizingMaskIntoConstraints = false
    body.text = nativeAd.body
    body.textColor = pal.body
    body.font = .systemFont(ofSize: 11)
    body.numberOfLines = 1
    body.lineBreakMode = .byTruncatingTail
    body.isHidden = (nativeAd.body ?? "").isEmpty
    adView.bodyView = body

    let cta = GradientPillButton(type: .system)
    cta.translatesAutoresizingMaskIntoConstraints = false
    cta.layer.cornerRadius = 14

    if #available(iOS 15.0, *) {
      cta.configuration = nil
    }
    cta.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

    let rawCta = (nativeAd.callToAction ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let ctaText = rawCta.isEmpty ? "Install" : rawCta
    let ctaFont = UIFont.systemFont(ofSize: 11, weight: .bold)
    let ctaAttrs: [NSAttributedString.Key: Any] = [
      .font: ctaFont,
      .foregroundColor: UIColor.white,
    ]
    cta.setTitle(nil, for: .normal)
    cta.setAttributedTitle(
      NSAttributedString(string: ctaText, attributes: ctaAttrs),
      for: .normal
    )
    cta.titleLabel?.text = ctaText
    cta.titleLabel?.textColor = .white
    cta.titleLabel?.font = ctaFont
    cta.titleLabel?.isHidden = false
    cta.titleLabel?.alpha = 1
    cta.tintColor = .white  

    cta.isHidden = false
    cta.setContentHuggingPriority(.required, for: .horizontal)
    cta.setContentCompressionResistancePriority(.required, for: .horizontal)

    cta.isUserInteractionEnabled = false
    adView.callToActionView = cta

    let media = MediaView()
    media.translatesAutoresizingMaskIntoConstraints = false
    media.alpha = 0
    adView.mediaView = media

    let badgeHeadlineRow = UIStackView(arrangedSubviews: [badge, headline])
    badgeHeadlineRow.translatesAutoresizingMaskIntoConstraints = false
    badgeHeadlineRow.axis = .horizontal
    badgeHeadlineRow.spacing = 6
    badgeHeadlineRow.alignment = .center

    let textCol = UIStackView(arrangedSubviews: [badgeHeadlineRow, body])
    textCol.translatesAutoresizingMaskIntoConstraints = false
    textCol.axis = .vertical
    textCol.spacing = 3
    textCol.alignment = .fill
    textCol.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textCol.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let mainRow = UIStackView(arrangedSubviews: [icon, textCol, cta])
    mainRow.translatesAutoresizingMaskIntoConstraints = false
    mainRow.axis = .horizontal
    mainRow.spacing = 10
    mainRow.alignment = .center
    icon.setContentHuggingPriority(.required, for: .horizontal)

    adView.addSubview(mainRow)
    adView.addSubview(media)

    NSLayoutConstraint.activate([
      mainRow.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      mainRow.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),
      mainRow.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
      mainRow.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor, constant: 6),
      mainRow.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -6),

      icon.widthAnchor.constraint(equalToConstant: 44),
      icon.heightAnchor.constraint(equalToConstant: 44),

      badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 14),

      cta.heightAnchor.constraint(equalToConstant: 28),
      cta.widthAnchor.constraint(lessThanOrEqualToConstant: 140),

      media.topAnchor.constraint(equalTo: adView.topAnchor),
      media.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      media.widthAnchor.constraint(equalToConstant: 120),
      media.heightAnchor.constraint(equalToConstant: 120),
    ])

    adView.nativeAd = nativeAd
    // The SDK can insert its own subviews when the native ad is assigned
    // (e.g. media/video overlays). Force our row — and the "Ad" badge inside
    // it — back to the front so it can never end up hidden behind SDK content.
    adView.bringSubviewToFront(mainRow)
    return adView
  }
}

final class ExpandedNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let isDark = (customOptions?["isDark"] as? Bool) ?? false
    let pal: (cardBg: UIColor, head: UIColor, body: UIColor, adv: UIColor, iconBg: UIColor) =
      isDark
        ? (DarkPalette.cardBg,  DarkPalette.headline,  DarkPalette.body,  DarkPalette.advertiser,  DarkPalette.iconBg)
        : (LightPalette.cardBg, LightPalette.headline, LightPalette.body, LightPalette.advertiser, LightPalette.iconBg)

    let adView = NativeAdView()
    adView.backgroundColor = pal.cardBg

    let media = MediaView()
    media.translatesAutoresizingMaskIntoConstraints = false
    media.contentMode = .scaleAspectFit
    media.backgroundColor = pal.iconBg
    media.layer.cornerRadius = 8
    media.clipsToBounds = true
    adView.mediaView = media

    let icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    icon.clipsToBounds = true
    icon.layer.cornerRadius = 10
    icon.backgroundColor = pal.iconBg
    icon.image = nativeAd.icon?.image
    adView.iconView = icon

    let headline = UILabel()
    headline.translatesAutoresizingMaskIntoConstraints = false
    headline.text = nativeAd.headline
    headline.textColor = pal.head
    headline.font = .systemFont(ofSize: 14, weight: .bold)
    headline.numberOfLines = 1
    adView.headlineView = headline

    let advertiser = UILabel()
    advertiser.translatesAutoresizingMaskIntoConstraints = false
    advertiser.text = nativeAd.advertiser
    advertiser.textColor = pal.adv
    advertiser.font = .systemFont(ofSize: 11)
    advertiser.numberOfLines = 1
    adView.advertiserView = advertiser

    let body = UILabel()
    body.translatesAutoresizingMaskIntoConstraints = false
    body.text = nativeAd.body
    body.textColor = pal.body
    body.font = .systemFont(ofSize: 12)
    body.numberOfLines = 1
    adView.bodyView = body

    let cta = UIButton(type: .system)
    cta.translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 15.0, *) {
      cta.configuration = nil
    }

    let expRawCta = (nativeAd.callToAction ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let expCtaText = expRawCta.isEmpty ? "Install" : expRawCta
    let expCtaFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    let expCtaFg = isDark ? Brand.onPrimaryDark : Brand.onPrimaryLight
    let expCtaAttrs: [NSAttributedString.Key: Any] = [
      .font: expCtaFont,
      .foregroundColor: expCtaFg,
    ]
    cta.setTitle(nil, for: .normal)
    cta.setAttributedTitle(
      NSAttributedString(string: expCtaText, attributes: expCtaAttrs),
      for: .normal
    )
    cta.titleLabel?.text = expCtaText
    cta.titleLabel?.textColor = expCtaFg
    cta.titleLabel?.font = expCtaFont
    cta.titleLabel?.isHidden = false
    cta.titleLabel?.alpha = 1
    cta.tintColor = expCtaFg

    cta.backgroundColor = isDark ? Brand.primaryDark : Brand.primaryLight
    cta.layer.cornerRadius = 16
    cta.clipsToBounds = true
    cta.isUserInteractionEnabled = false
    adView.callToActionView = cta

    let badge = PaddedLabel()
    badge.translatesAutoresizingMaskIntoConstraints = false
    badge.text = "Ad"
    badge.textColor = .white
    badge.font = .systemFont(ofSize: 10, weight: .bold)
    badge.backgroundColor = Brand.blue
    badge.layer.cornerRadius = 4
    badge.clipsToBounds = true
    badge.textAlignment = .center
    badge.accessibilityLabel = "Advertisement"
    badge.isAccessibilityElement = true
    badge.setContentHuggingPriority(.required, for: .horizontal)
    badge.setContentCompressionResistancePriority(.required, for: .horizontal)

    let textCol = UIStackView(arrangedSubviews: [headline, advertiser])
    textCol.translatesAutoresizingMaskIntoConstraints = false
    textCol.axis = .vertical
    textCol.spacing = 2

    let iconRow = UIStackView(arrangedSubviews: [icon, textCol])
    iconRow.translatesAutoresizingMaskIntoConstraints = false
    iconRow.axis = .horizontal
    iconRow.spacing = 8
    iconRow.alignment = .center

    adView.addSubview(media)
    adView.addSubview(iconRow)
    adView.addSubview(body)
    adView.addSubview(cta)
    adView.addSubview(badge)

    NSLayoutConstraint.activate([
      media.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      media.heightAnchor.constraint(equalToConstant: 180),

      icon.widthAnchor.constraint(equalToConstant: 48),
      icon.heightAnchor.constraint(equalToConstant: 48),

      iconRow.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 8),
      iconRow.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      iconRow.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      iconRow.heightAnchor.constraint(equalToConstant: 48),

      body.topAnchor.constraint(equalTo: iconRow.bottomAnchor, constant: 4),
      body.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      body.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),

      cta.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 8),
      cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      cta.heightAnchor.constraint(equalToConstant: 52),
      cta.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),

      badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      badge.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
    ])

    adView.nativeAd = nativeAd
    // Same reasoning as the list-tile factory: guarantee the badge renders
    // above anything the SDK adds once the native ad is assigned, since on
    // iPad different ad creatives/media formats are more likely to trigger
    // SDK-inserted overlay subviews that can otherwise cover it.
    adView.bringSubviewToFront(badge)
    return adView
  }
}
