import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralised ad configuration.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad Unit IDs (production) ──
  static const String _bannerAdUnitId =
      'ca-app-pub-1494880985491294/9749518301';
  static const String _interstitialAdUnitId =
      'ca-app-pub-1494880985491294/3692569352';
  static const String _nativeAdUnitId =
      'ca-app-pub-1494880985491294/2243756310';

  /// Whether the current platform supports mobile ads.
  static bool get isSupported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  // ── Getters ──
  static String get bannerAdUnitId => _bannerAdUnitId;
  static String get interstitialAdUnitId => _interstitialAdUnitId;
  static String get nativeAdUnitId => _nativeAdUnitId;

  // ── Initialisation ──
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised || !isSupported) return;
    await MobileAds.instance.initialize();
    _initialised = true;
    debugPrint('[AdService] MobileAds SDK initialised');
  }

  // ── Interstitial helper ──
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Pre‑load an interstitial so it's ready when needed.
  void preloadInterstitial() {
    if (!isSupported || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial failed: $error');
        },
      ),
    );
  }

  /// Show the pre‑loaded interstitial (once). Returns true if shown.
  Future<bool> showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) return false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        debugPrint('[AdService] Interstitial show error: $error');
      },
    );

    await ad.show();
    _interstitialAd = null;
    return true;
  }
}
