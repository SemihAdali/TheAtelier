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

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_foundProduct) {
        _foundProduct = true;
        if (Navigator.canPop(context)) {
          Navigator.pop(context, null);
        }
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _scanForProductData() async {
    if (_foundProduct || webViewController == null) return;

    final jsCode = '''
      (function() {
        var res = { title: '', image: '', brand: '', price: '', currency: '', size: '' };
        var findPrice = function(obj) {
          if (!obj || typeof obj !== 'object') return null;
          if (obj.price && obj.priceCurrency) return obj;
          if (Array.isArray(obj)) {
            for (var i=0; i<obj.length; i++) {
               var r = findPrice(obj[i]);
               if (r) return r;
            }
          } else {
            for (var k in obj) {
               var r = findPrice(obj[k]);
               if (r) return r;
            }
          }
          return null;
        };

        try {
          var schemas = document.querySelectorAll('script[type="application/ld+json"]');
          for (var i=0; i<schemas.length; i++) {
             var text = schemas[i].innerText;
             if (!text) continue;
             var schemaData = JSON.parse(text);
             var products = [];
             if (Array.isArray(schemaData)) {
                 products = schemaData.filter(x => x['@type'] === 'Product' || x['@type'] === 'ProductGroup');
             } else if (schemaData['@type'] === 'Product' || schemaData['@type'] === 'ProductGroup') {
                 products = [schemaData];
             } else if (schemaData['@graph']) {
                 products = schemaData['@graph'].filter(x => x['@type'] === 'Product');
             }
             
             if (products.length > 0) {
                var p = products[0];
                res.title = p.name || res.title;
                res.image = Array.isArray(p.image) ? p.image[0] : (p.image || res.image);
                if (typeof res.image === 'object' && res.image.url) res.image = res.image.url;
                
                if (p.brand) {
                   if (typeof p.brand === 'string') res.brand = p.brand;
                   else if (p.brand.name) res.brand = p.brand.name;
                }
             }
             
             if (!res.price) {
                var offer = findPrice(schemaData);
                if (offer) {
                   res.price = offer.price || offer.lowPrice;
                   res.currency = offer.priceCurrency;
                }
             }
          }
        } catch(e) {}
        
        var getMeta = function(prop) {
           var el = document.querySelector('meta[property="' + prop + '"]') || document.querySelector('meta[name="' + prop + '"]');
           return el ? el.content : null;
        };
        
        if (!res.title) res.title = getMeta('og:title') || document.title;
        if (!res.image) res.image = getMeta('og:image');
        if (!res.price) res.price = getMeta('product:price:amount') || getMeta('price');
        if (!res.currency) res.currency = getMeta('product:price:currency') || getMeta('currency');
        if (!res.brand) res.brand = getMeta('product:brand') || getMeta('brand') || getMeta('og:brand');
        
        if (!res.price) {
           var bodyText = document.body.innerText;
           var match = bodyText.match(/(?:\\b|^)(?:EUR|\\€|CHF|\\\$|\\£)?\\s*([0-9]{1,4}[,.-][0-9]{2})\\s*(?:EUR|\\€|CHF|\\\$|\\£)?(?:\\b|\$)/i);
           if (match) {
              res.price = match[1].replace('-', '00');
           } else {
              var priceEl = document.querySelector('[data-testid="detail-price"], .price, [class*="price" i]');
              if (priceEl) {
                 var m = priceEl.innerText.match(/([0-9]{1,4}(?:[,.][0-9]{2})?)/);
                 if (m) res.price = m[1];
              }
           }
        }
        if (!res.brand) {
           var brandEl = document.querySelector('[data-testid="detail-brand"], .brand, [class*="brand" i]');
           if (brandEl) {
              res.brand = brandEl.innerText.trim().split('\\n')[0];
           }
        }
        
        if (typeof res.price === 'number') res.price = res.price.toString();
        if (typeof res.title !== 'string') res.title = '';
        if (typeof res.brand !== 'string') res.brand = '';
        if (typeof res.image !== 'string') res.image = '';
        
        return JSON.stringify(res);
      })();
    ''';
    
    try {
      final jsonString = await webViewController!.evaluateJavascript(source: jsCode) as String?;
      if (_foundProduct) return;
      
      if (jsonString != null && mounted) {
         final Map<String, dynamic> result = jsonDecode(jsonString);
         final titleInfo = result['title']?.toString().toLowerCase() ?? '';
         
         if (result['title'] != null && 
             result['title'].toString().isNotEmpty && 
             !titleInfo.contains('access denied') &&
             !titleInfo.contains('just a moment') &&
             !titleInfo.contains('attention required') &&
             !titleInfo.contains('security measure')) {
             
             _foundProduct = true;
             _timeoutTimer?.cancel();
             if (Navigator.canPop(context)) {
                 Navigator.pop(context, result);
             }
         }
      }
    } catch(e) {
      debugPrint("Evaluator exception: \$e");
    }
  }

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
          Opacity(
             opacity: 0.0,
             child: InAppWebView(
               initialUrlRequest: URLRequest(url: WebUri(secureUrl)),
               initialSettings: InAppWebViewSettings(
                 javaScriptEnabled: true,
                 userAgent: 'Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
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
                     const SnackBar(content: Text('Scanner engine crashed. Please enter details manually.')),
                   );
                 }
               },
               onProgressChanged: (controller, progress) {
                 setState(() {
                   _progress = progress / 100;
                 });
                 if (progress >= 50) {
                   _scanForProductData();
                 }
               },
               onLoadStop: (controller, url) async {
                 _scanForProductData();
               },
             ),
          ),
          
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
