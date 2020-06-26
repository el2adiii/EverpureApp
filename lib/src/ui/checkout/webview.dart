import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../blocs/home_bloc.dart';
import '../../resources/api_provider.dart';
import 'order_summary.dart';
import 'dart:io';

class WebViewPage extends StatefulWidget {
  final String url;
  final String selectedPaymentMethod;
  final HomeBloc homeBloc;

  const WebViewPage({Key key, this.url, this.selectedPaymentMethod, this.homeBloc}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState(url: url);
}

class _WebViewPageState extends State<WebViewPage> {
  final String url;
  final apiProvider = ApiProvider();
  bool _isLoadingPage;
  String orderId;
  String redirect;
  WebViewController controller;
  final CookieManager cookieManager = CookieManager();
  List<Cookie> cookies = [];
  String sessionId;
  String redirectUrl;

  @override
  void initState() {
    super.initState();
    _isLoadingPage = true;
    orderId = '0';
    if (url.lastIndexOf("/order-pay/") != -1 &&
        url.lastIndexOf("/?key=wc_order") != -1) {
      var pos1 = url.lastIndexOf("/order-pay/");
      var pos2 = url.lastIndexOf("/?key=wc_order");
      orderId = url.substring(pos1 + 11, pos2);
    }

    if (widget.selectedPaymentMethod == 'woo_mpgs' && url.lastIndexOf("sessionId=") != -1 &&
        url.lastIndexOf("&order=") != -1) {
      var pos1 = url.lastIndexOf("sessionId=");
      var pos2 = url.lastIndexOf("&order=");
      String sessionId = url.substring(pos1 + 10, pos2);
      redirectUrl = 'https://credimax.gateway.mastercard.com/checkout/pay/' + sessionId;
    } else {
      redirectUrl = url;
    }
  }

  _WebViewPageState({this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 1.0, title: Text('Payment')),
      body: Container(
        child: Stack(
          children: <Widget>[
            WebView(
              navigationDelegate: (NavigationRequest request) {
                controller.currentUrl().then(onValue);
                return NavigationDecision.navigate;
              },
              initialUrl: redirectUrl,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController wvc) {
                controller = wvc;
                //controller.evaluateJavascript("document.cookie = woocommerce_cart_hash=84337ed45f65479853ac9c64d47cb249; woocommerce_items_in_cart=1");
                //
              },
              onPageFinished: (finish) async {
                controller.evaluateJavascript('document.cookie = "${apiProvider.generateCookieHeader()}"');
                setState(() {
                  _isLoadingPage = false;
                });
              },
              //debuggingEnabled: true,
            ),
            _isLoadingPage
                ? Container(
                    alignment: FractionalOffset.center,
                    child: CircularProgressIndicator(),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  void _onNavigationDelegateExample(
      WebViewController controller, BuildContext context) async {
    controller.currentUrl().then(onValue);
  }

  Future onValue(String url) {
    if (url.contains('/order-received/')) {
      orderSummary(url);
    }

    if (url.contains('cancel_order=') ||
        url.contains('failed') ||
        url.contains('type=error') ||
        url.contains('cancelled=1') ||
        url.contains('cancelled') ||
        url.contains('cancel_order=true')) {
       // Navigator.of(context).pop();
    }

    if (url.contains('?errors=true')) {
     // Navigator.of(context).pop();
    }

    // Start of PayUIndia Payment
    if (url.contains('payumoney.com/transact')) {
      // Show WebView
    }

    if (url.contains('/order-received/') &&
        url.contains('key=wc_order_') &&
        orderId != null) {
        navigateOrderSummary(url);
    }
    // End of PayUIndia Payment

    // Start of PAYTM Payment
    if (url.contains('securegw-stage.paytm.in/theia')) {
      //Show WebView
    }

    if (url.contains('type=success') && orderId != null) {
      navigateOrderSummary(url);
    }

  }

  void orderSummary(String url) {
    var str = url;
    var pos1 = str.lastIndexOf("/order-received/");
    var pos2 = str.lastIndexOf("/?key=wc_order");
    orderId = str.substring(pos1 + 16, pos2);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderSummary(
                id: orderId,
            )));
  }

  void navigateOrderSummary(String url) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderSummary(
                id: orderId,
            )));
  }
}
