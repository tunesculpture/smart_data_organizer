import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitial(); // preload next immediately
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          // Retry after 30 seconds
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Call this after every successful parse/export
  void showInterstitialIfReady() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
    }
  }
}

// ── Banner Ad Widget ──────────────────────────────────────────────────────────
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _isLoaded = true); },
        onAdFailedToLoad: (ad, _) { ad.dispose(); _bannerAd = null; },
      ),
    )..load();
  }

  @override
  void dispose() { _bannerAd?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
