package com.example.easy_translate

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

class ExpandedNativeAdFactory(private val context: Context) :
    NativeAdFactory {

    private object Brand {
        const val blue = 0xFF3B82F6.toInt()
        const val violet = 0xFF8B5CF6.toInt()

        const val primaryLight = 0xFF2563EB.toInt()
        const val primaryDark = 0xFF60A5FA.toInt()
        const val onPrimaryLight = 0xFFFFFFFF.toInt()
        const val onPrimaryDark = 0xFF071029.toInt()
    }

    private object Light {
        const val cardBg = Color.WHITE
        const val headline = 0xFF0F172A.toInt()    
        const val body = 0xFF475569.toInt()      
        const val advertiser = 0xFF94A3B8.toInt()   
        const val iconBg = 0xFFEEF2FF.toInt()      
    }

    private object Dark {
        const val cardBg = 0xFF111A33.toInt()       
        const val headline = 0xFFE2E8F0.toInt()     
        const val body = 0xFFB6BFCB.toInt()
        const val advertiser = 0xFF94A3B8.toInt() 
        const val iconBg = 0xFF1B2547.toInt()      
    }

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val isDark = (customOptions?.get("isDark") as? Boolean) == true

        val adView = LayoutInflater
            .from(context)
            .inflate(R.layout.expanded_native_ad, null) as NativeAdView

        adView.findViewById<LinearLayout>(R.id.native_ad_card)?.setBackgroundColor(
            if (isDark) Dark.cardBg else Light.cardBg
        )

        adView.findViewById<TextView>(R.id.native_ad_attribution)?.apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(4f)
                setColor(Brand.blue)
            }
        }

        adView.findViewById<ImageView>(R.id.native_ad_icon)?.let {
            it.background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(10f)
                setColor(if (isDark) Dark.iconBg else Light.iconBg)
            }
            it.clipToOutline = true
            val icon = nativeAd.icon
            it.setImageDrawable(icon?.drawable)
            it.visibility = View.VISIBLE
            adView.iconView = it
        }

        adView.findViewById<TextView>(R.id.native_ad_headline).let {
            it.text = nativeAd.headline
            it.setTextColor(if (isDark) Dark.headline else Light.headline)
            adView.headlineView = it
        }

        adView.findViewById<TextView>(R.id.native_ad_body)?.let {
            it.text = nativeAd.body
            it.visibility = if (nativeAd.body == null) View.GONE else View.VISIBLE
            it.setTextColor(if (isDark) Dark.body else Light.body)
            adView.bodyView = it
        }

        adView.findViewById<TextView>(R.id.native_ad_advertiser)?.let {
            it.text = nativeAd.advertiser
            it.visibility = if (nativeAd.advertiser == null) View.GONE else View.VISIBLE
            it.setTextColor(if (isDark) Dark.advertiser else Light.advertiser)
            adView.advertiserView = it
        }

        adView.findViewById<RatingBar>(R.id.native_ad_rating)?.let {
            val rating = nativeAd.starRating
            if (rating == null) {
                it.visibility = View.GONE
            } else {
                it.rating = rating.toFloat()
                it.visibility = View.VISIBLE
            }
            adView.starRatingView = it
        }

        adView.findViewById<Button>(R.id.native_ad_button)?.let {
            it.text = nativeAd.callToAction ?: "Install"
            it.visibility = if (nativeAd.callToAction == null) View.GONE else View.VISIBLE
            it.background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16f)
                setColor(if (isDark) Brand.primaryDark else Brand.primaryLight)
            }
            it.setTextColor(
                if (isDark) Brand.onPrimaryDark else Brand.onPrimaryLight
            )
            adView.callToActionView = it
        }

        adView.findViewById<MediaView>(R.id.native_ad_media)?.let {
            it.visibility = View.VISIBLE
            adView.mediaView = it
        }

        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun dp(value: Float): Float =
        value * context.resources.displayMetrics.density
}
