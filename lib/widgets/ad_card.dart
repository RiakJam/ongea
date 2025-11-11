import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdCard extends StatefulWidget {
  final bool isTestAd;

  const AdCard({
    Key? key,
    this.isTestAd = false, // Default to false for production
  }) : super(key: key);

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  // ✅ Replace this with your real Ad Unit ID from AdMob
  static const String productionBannerAdUnitId =
      'ca-app-pub-9852675207126397/2573022864';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = widget.isTestAd
        ? 'ca-app-pub-3940256099942544/6300978111' // ✅ Google test banner
        : productionBannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle, // Better for feed-style placement
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
            _isAdFailed = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
            _isAdFailed = true;
          });
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
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Colors.orange.shade100),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      child: Stack(
        children: [
          // Ad content area
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.grey[200],
            ),
            child: _isAdLoaded && _bannerAd != null
                ? Container(
                    alignment: Alignment.center,
                    child: AdWidget(ad: _bannerAd!),
                    height: _bannerAd!.size.height.toDouble(),
                    width: _bannerAd!.size.width.toDouble(),
                  )
                : _isAdFailed
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.error_outline, color: Colors.grey),
                            SizedBox(height: 6),
                            Text(
                              'Ad failed to load',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
          ),

          // "Sponsored" tag
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Sponsored",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Debug info for test ads
          if (widget.isTestAd)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '⚠️ Test Ad – will be replaced with real ads in production.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
