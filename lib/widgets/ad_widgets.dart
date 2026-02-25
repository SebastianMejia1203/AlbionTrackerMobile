import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BannerAdWidget  –  Standard 320×50 banner (or adaptive)
// ─────────────────────────────────────────────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  /// Use [AdSize.banner] (320×50) or [AdSize.mediumRectangle] (300×250).
  final AdSize adSize;
  const BannerAdWidget({super.key, this.adSize = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BannerAdWidget] Failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isSupported || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // invisible on desktop / if not loaded
    }
    return Container(
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  InlineBannerAd  –  A banner meant to be inserted inside a ListView
// ─────────────────────────────────────────────────────────────────────────────

class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

    _ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.mediumRectangle, // 300×250 – blends well in lists
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[InlineBannerAd] Failed: $error');
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isSupported || !_isLoaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      width: 300,
      height: 250,
      child: AdWidget(ad: _ad!),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: insert an ad every N items in a list
// ─────────────────────────────────────────────────────────────────────────────

/// Given a real item count, returns the total count with ad slots injected.
int itemCountWithAds(int realCount, {int interval = 8}) {
  if (!AdService.isSupported || realCount == 0) return realCount;
  return realCount + (realCount ~/ interval);
}

/// Returns `true` when [index] corresponds to an ad slot.
bool isAdIndex(int index, {int interval = 8}) {
  if (!AdService.isSupported) return false;
  // Ad positions: interval, interval*2+1, interval*3+2, …
  return index > 0 && (index + 1) % (interval + 1) == 0;
}

/// Maps a list‑view index (with ad slots) to the real item index.
int realItemIndex(int index, {int interval = 8}) {
  if (!AdService.isSupported) return index;
  return index - (index ~/ (interval + 1));
}
