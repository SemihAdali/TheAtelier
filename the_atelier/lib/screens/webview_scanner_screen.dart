import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScannerScreen extends StatefulWidget {
  final String url;

  const WebViewScannerScreen({super.key, required this.url});

  @override
  State<WebViewScannerScreen> createState() => _WebViewScannerScreenState();
}

class _WebViewScannerScreenState extends State<WebViewScannerScreen> {
  double _progress = 0;
  InAppWebViewController? webViewController;
  bool _foundProduct = false;
  Timer? _timeoutTimer;
  Timer? _pollTimer;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    // Hard timeout: after 20s return whatever we have
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && !_foundProduct) {
        _tryFinalReturn();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (_pollTimer != null) return; // Already running
    // Poll every 1.5 s to catch dynamically-rendered content
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _scanForProductData();
    });
  }

  /// Returns whatever was scraped when the hard timeout fires
  Future<void> _tryFinalReturn() async {
    if (_foundProduct || webViewController == null) return;
    _pollTimer?.cancel();
    _foundProduct = true;
    try {
      final raw = await webViewController!.evaluateJavascript(source: _jsCode) as String?;
      if (raw != null && mounted) {
        final result = jsonDecode(raw) as Map<String, dynamic>;
        if (Navigator.canPop(context)) {
          Navigator.pop(context, result['title']?.toString().isNotEmpty == true ? result : null);
        }
      } else if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, null);
      }
    } catch (_) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context, null);
    }
  }

  Future<void> _scanForProductData() async {
    if (_foundProduct || webViewController == null || !_pageLoaded) return;

    try {
      final raw = await webViewController!.evaluateJavascript(source: _jsCode) as String?;
      if (_foundProduct) return;

      if (raw != null && mounted) {
        final Map<String, dynamic> result = jsonDecode(raw);
        final title = result['title']?.toString() ?? '';
        final titleLower = title.toLowerCase();
        final price = result['price']?.toString() ?? '';
        final brand = result['brand']?.toString() ?? '';

        // Skip bot-check / error pages — keep polling
        if (titleLower.contains('access denied') ||
            titleLower.contains('just a moment') ||
            titleLower.contains('attention required') ||
            titleLower.contains('security measure')) {
          return;
        }

        // Only accept when we have enough data.
        // Require title + at least one of price OR brand.
        // This prevents accepting a half-rendered page.
        if (title.isNotEmpty && (price.isNotEmpty || brand.isNotEmpty)) {
          _foundProduct = true;
          _pollTimer?.cancel();
          _timeoutTimer?.cancel();
          if (Navigator.canPop(context)) {
            Navigator.pop(context, result);
          }
        }
        // If only title found → keep polling, page is still rendering
      }
    } catch (e) {
      debugPrint('Scanner poll error: $e');
    }
  }

  // ─── JavaScript ──────────────────────────────────────────────────────────────
  // Written as a Dart raw string so that regex backslashes (\d, \s, etc.)
  // are sent verbatim to the WebView engine without double-escaping.
  // Old-style function() syntax for max Android WebView compatibility.
  static const String _jsCode = r'''
    (function() {
      var res = { title: '', image: '', brand: '', price: '', currency: '' };

      // ── Helper: walk an LD+JSON object tree looking for an Offer node ──
      var findOffer = function(obj) {
        if (!obj || typeof obj !== 'object') return null;
        if (obj.price && obj.priceCurrency) return obj;
        if (Array.isArray(obj)) {
          for (var i = 0; i < obj.length; i++) { var r = findOffer(obj[i]); if (r) return r; }
        } else {
          for (var k in obj) { var r = findOffer(obj[k]); if (r) return r; }
        }
        return null;
      };

      // ── Layer 1: LD+JSON structured data (most reliable) ──────────────
      try {
        var schemas = document.querySelectorAll('script[type="application/ld+json"]');
        for (var i = 0; i < schemas.length; i++) {
          var txt = schemas[i].innerText || schemas[i].textContent;
          if (!txt) continue;
          var sd;
          try { sd = JSON.parse(txt); } catch(pe) { continue; }

          var products = [];
          if (Array.isArray(sd)) {
            products = sd.filter(function(x) { return x['@type'] === 'Product' || x['@type'] === 'ProductGroup'; });
          } else if (sd['@type'] === 'Product' || sd['@type'] === 'ProductGroup') {
            products = [sd];
          } else if (sd['@graph']) {
            products = sd['@graph'].filter(function(x) { return x['@type'] === 'Product'; });
          }

          if (products.length > 0) {
            var p = products[0];
            if (p.name && !res.title)  res.title = String(p.name);
            if (p.image && !res.image) {
              res.image = Array.isArray(p.image) ? p.image[0] : p.image;
              if (res.image && typeof res.image === 'object') res.image = res.image.url || res.image.contentUrl || '';
              res.image = String(res.image || '');
            }
            if (p.brand && !res.brand) {
              res.brand = typeof p.brand === 'string' ? p.brand : (p.brand.name || '');
            }
          }

          if (!res.price) {
            var offer = findOffer(sd);
            if (offer) {
              res.price = String(offer.price || offer.lowPrice || '');
              res.currency = String(offer.priceCurrency || '');
            }
          }
        }
      } catch(e1) {}

      // ── Layer 2: Open Graph / meta tags ───────────────────────────────
      var getMeta = function(prop) {
        var el = document.querySelector('meta[property="' + prop + '"]') ||
                 document.querySelector('meta[name="' + prop + '"]');
        return el ? (el.content || '') : '';
      };
      if (!res.title)    res.title    = getMeta('og:title')               || document.title || '';
      if (!res.image)    res.image    = getMeta('og:image')               || getMeta('og:image:secure_url') || '';
      if (!res.price)    res.price    = getMeta('product:price:amount')   || getMeta('price') || '';
      if (!res.currency) res.currency = getMeta('product:price:currency') || '';
      if (!res.brand)    res.brand    = getMeta('product:brand')          || getMeta('og:brand') || '';

      // ── Layer 3: Extra image fallbacks (for shops without og:image) ───
      if (!res.image) {
        try {
          var linkImg = document.querySelector('link[rel="image_src"]');
          if (linkImg) res.image = linkImg.href || '';
        } catch(ei1) {}
      }
      if (!res.image) {
        try {
          var itemImg = document.querySelector('[itemprop="image"]');
          if (itemImg) res.image = itemImg.src || itemImg.content || itemImg.getAttribute('content') || '';
        } catch(ei2) {}
      }
      if (!res.image) {
        try {
          var imgSelectors = [
            '.product-image img', '.product-img img', '.product-main-image img',
            '#product-image img', '.gallery-image img', '.pdp-image img',
            '.product-gallery img', '[data-testid="product-image"] img',
            '.swiper-slide img', '.detail-image img', '.hero-image img'
          ];
          for (var si = 0; si < imgSelectors.length; si++) {
            var el = document.querySelector(imgSelectors[si]);
            if (el && el.src && el.src.indexOf('http') === 0) { res.image = el.src; break; }
          }
        } catch(ei3) {}
      }
      if (!res.image) {
        // Last resort: find the largest visible image on the page
        try {
          var allImgs = document.querySelectorAll('img');
          var bestSrc = '', bestArea = 0;
          for (var ii = 0; ii < allImgs.length; ii++) {
            var img = allImgs[ii];
            var src = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src') || '';
            if (!src || src.indexOf('http') !== 0) continue;
            var w = img.naturalWidth || img.width || 0;
            var h = img.naturalHeight || img.height || 0;
            var area = w * h;
            if (area > bestArea && w > 150 && h > 150) { bestArea = area; bestSrc = src; }
          }
          if (bestSrc) res.image = bestSrc;
        } catch(ei4) {}
      }

      // ── Layer 4: Price fallbacks ───────────────────────────────────────
      if (!res.price) {
        try {
          // Regex over body text — catches "€ 49,99", "49.99 EUR", "CHF 129.–"
          var bodyText = document.body ? document.body.innerText : '';
          var m = bodyText.match(/(?:EUR|\u20ac|CHF|\$|\u00a3)\s*([0-9]{1,4}[,.][0-9]{2})|([0-9]{1,4}[,.][0-9]{2})\s*(?:EUR|\u20ac|CHF|\$|\u00a3)/i);
          if (m) res.price = m[1] || m[2];
        } catch(e4) {}
      }
      if (!res.price) {
        try {
          var priceEl = document.querySelector(
            '.price, .price-box, .price-current, .price-sale, ' +
            '[data-testid="product-price"], [class*="price" i], [itemprop="price"]'
          );
          if (priceEl) {
            var pm = (priceEl.innerText || priceEl.getAttribute('content') || '').match(/([0-9]+[,.]?[0-9]*)/);
            if (pm) res.price = pm[1];
          }
        } catch(e5) {}
      }

      // ── Layer 5: Brand fallbacks ──────────────────────────────────────
      if (!res.brand) {
        try {
          var brandEl = document.querySelector(
            '.brand, [itemprop="brand"], [data-testid="product-brand"], ' +
            '[class*="brand" i], [class*="manufacturer" i]'
          );
          if (brandEl) res.brand = (brandEl.innerText || '').trim().split('\n')[0].trim();
        } catch(e6) {}
      }

      // ── Sanitise output ───────────────────────────────────────────────
      if (typeof res.price    === 'number') res.price    = String(res.price);
      if (typeof res.title    !== 'string') res.title    = '';
      if (typeof res.brand    !== 'string') res.brand    = '';
      if (typeof res.image    !== 'string') res.image    = '';
      if (typeof res.currency !== 'string') res.currency = '';

      return JSON.stringify(res);
    })();
  ''';

  @override
  Widget build(BuildContext context) {
    String secureUrl = widget.url;
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scanning Shop...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Hidden WebView — we only use it to evaluate JS, not show it
          Opacity(
            opacity: 0.0,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(secureUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 13; SM-S901B) '
                    'AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/120.0.0.0 Mobile Safari/537.36',
                preferredContentMode: UserPreferredContentMode.MOBILE,
                transparentBackground: true,
                hardwareAcceleration: false,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onRenderProcessGone: (controller, detail) async {
                if (mounted) {
                  Navigator.pop(context, null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scanner crashed. Please enter details manually.')),
                  );
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
                // Start polling early — many shops render key data by 70 %
                if (progress >= 70) {
                  _pageLoaded = true;
                  _startPolling();
                }
              },
              onLoadStop: (controller, url) async {
                _pageLoaded = true;
                _startPolling();
              },
            ),
          ),

          // Loading overlay
          Container(
            color: Theme.of(context).colorScheme.surface,
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 32),
                Text(
                  'Magic is happening...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Extracting product details from the shop',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (_progress > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
