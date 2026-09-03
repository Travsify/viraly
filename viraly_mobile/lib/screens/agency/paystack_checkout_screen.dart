import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme.dart';

class PaystackCheckoutScreen extends StatefulWidget {
  final String authorizationUrl;
  final String callbackUrlFragment;

  const PaystackCheckoutScreen({
    super.key,
    required this.authorizationUrl,
    this.callbackUrlFragment = '/api/agency/campaigns/payment-callback',
  });

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Detect callback URL — payment completed
            if (!_completed && url.contains(widget.callbackUrlFragment)) {
              setState(() => _completed = true);
              Navigator.pop(context, true); // Return success
            }
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // Allow all Paystack and callback URLs
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViralyTheme.background,
      appBar: AppBar(
        title: const Text('Fund Campaign Escrow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ViralyTheme.emerald),
              ),
            ),
        ],
      ),
    );
  }
}
