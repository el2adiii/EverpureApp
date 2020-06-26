import 'dart:async';
import './../models/category_model.dart';
import 'package:http/http.dart' show Client;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiProvider {

  static final ApiProvider _apiProvider = new ApiProvider._internal();

  String lan = 'en';

  factory ApiProvider() {
    return _apiProvider;
  }

  Future init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    lan = prefs.getString('language_code') != null ? prefs.getString('language_code') : 'en';
  }

  ApiProvider._internal();

  Client client = Client();
  Map<String, String> headers = {
    "content-type": "application/x-www-form-urlencoded; charset=utf-8"
  };
  Map<String, dynamic> cookies = {};
  List<Cookie> cookieList = [];

  var url = 'http://example.com'; //Replace This
  var consumerKey = 'ck_76973960a31c0cabretet1693abf161de5db7'; //Replace This
  var consumerSecret = 'cs_449e4f6508c90bgdfgfdsdc6e1c6bcf532'; //Replace This


  Future<http.Response> fetchBlocks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cookies = prefs.getString('cookies') != null ? json.decode(prefs.getString('cookies')) : {};
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    headers['cookie'] = generateCookieHeader();
    final response = await http.post(
      Uri.parse(url + '/wp-admin/admin-ajax.php?action=mstore_flutter-keys'),
      headers: headers,
      body: {'lang': lan, 'flutter_app': '1'},
    );
    if (response.statusCode == 200) {
      prefs.setString('blocks', response.body);
      return response;
    } else {
      throw Exception('Failed to load Blocks');
    }
  }

  Future<List<Product>>fetchProductList(filter) async {
    filter['lang'] = lan;
    filter['flutter_app'] = '1';
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
      Uri.parse(url + '/wp-admin/admin-ajax.php?action=mstore_flutter-products'),
      headers: headers,
      body: filter,
    );
    if (response.statusCode == 200) {
      return productModelFromJson(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> fetchRecentProducts(data) async {
    data['lang'] = lan;
    data['flutter_app'] = '1';
    final response = await http.post(
      Uri.parse(url + '/wp-admin/admin-ajax.php?action=mstore_flutter-products'),
      headers: headers,
      body: data,
    );
    if (response.statusCode == 200) {
      return productModelFromJson(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<dynamic> fetchProducts(data) async {
    data['lang'] = lan;
    data['flutter_app'] = '1';
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
      Uri.parse(url + '/wp-admin/admin-ajax.php?action=mstore_flutter-products'),
      headers: headers,
      body: data,
    );
    return response;
  }

  Future<dynamic> get(String endPoint) async {
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.get(
      Uri.parse(url + endPoint + '&lang=' + lan + '&flutter_app=' + '1'),
      headers: headers,
    );
    _updateCookie(response);
    return response;
  }

  Future<dynamic> postWithCookies(String endPoint, Map data) async {
    data['lang'] = lan;
    data['flutter_app'] = '1';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cookies = prefs.getString('cookies') != null ? json.decode(prefs.getString('cookies')) : {};
    headers['cookie'] = generateCookieHeader();
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
      Uri.parse(url + endPoint),
      headers: headers,
      body: data,
    );
    _updateCookie(response);
    return response;
  }

  Future<dynamic> post(String endPoint, Map data) async {
    data['lang'] = lan;
    data['flutter_app'] = '1';
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    print(url+endPoint);
    final response = await http.post(
      Uri.parse(url + endPoint),
      headers: headers,
      body: data,
    );
    _updateCookie(response);
    return response;
  }

  Future<dynamic> adminAjaxWithoutLanCode(String endPoint, Map data) async {
    data['lang'] = lan;
    data['flutter_app'] = '1';
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
      Uri.parse(url + endPoint),
      headers: headers,
      body: data,
    );
    _updateCookie(response);
    return response;
  }

  void _updateCookie(http.Response response) async {
    String allSetCookie = response.headers['set-cookie'];
    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');
      for (var setCookie in setCookies) {
        var cookies = setCookie.split(';');
        for (var cookie in cookies) {
          _setCookie(cookie);
        }
      }
      headers['cookie'] = generateCookieHeader();
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cookies', json.encode(cookies));
  }

  void _setCookie(String rawCookie) {
    if (rawCookie.length > 0) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];
        if (key == 'path') return;
        cookies[key] = value;
      }
    }
  }

  String generateCookieHeader() {
    String cookie = "";
    for (var key in cookies.keys) {
      if (cookie.length > 0) cookie += "; ";
      cookie += key + "=" + cookies[key];
    }
    return cookie;
  }

  String generateWebViewCookieHeader() {
    String cookie = "";
    for (var key in cookies.keys) {
      if( key.contains('woocommerce') ||
          key.contains('wordpress')
      ) {
        if (cookie.length > 0) cookie += "; ";
        cookie += key + "=" + cookies[key];
      }
    }
    return cookie;
  }

  List<Cookie> generateCookies() {
    for (var key in cookies.keys) {
      Cookie ck = new Cookie(key, cookies[key]);
      cookieList.add(ck);
    }
    return cookieList;
  }

  Future<dynamic> getPaymentUrl(String endPoint) async {
    headers['cookie'] = generateCookieHeader();
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
      Uri.parse(endPoint),
      headers: headers,
    );
    _updateCookie(response);
    return response;
  }

  Future<dynamic> posAjax(String url, Map data) async {
    headers['cookie'] = generateCookieHeader();
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=utf-8';
    final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: data
    );
    _updateCookie(response);
    return response;
  }

  processCredimaxPayment(redirect) async {
    headers['content-type'] =
    'application/x-www-form-urlencoded; charset=UTF-8';
    headers['Accept'] =
    'application/json, text/javascript, */*; q=0.01';
    final response = await http.post(
      Uri.parse('https://credimax.gateway.mastercard.com/api/page/version/49/pay'),
      headers: headers,
      body: redirect,
    );
    _updateCookie(response);
    return response;
  }
}
