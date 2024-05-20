import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

enum VNPayHashType {
  SHA256,
  HMACSHA512,
}

class VNPAYFlutter {
  static final VNPAYFlutter _instance = VNPAYFlutter();
  static VNPAYFlutter get instance => _instance;
  Map<String, dynamic> _sortParams(Map<String, dynamic> params) {
    final sortedParams = <String, dynamic>{};
    final keys = params.keys.toList()..sort();
    for (String key in keys) {
      sortedParams[key] = params[key];
    }
    return sortedParams;
  }

  String generatePaymentUrl({
    String url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    required String version,
    String command = 'pay',
    required String tmnCode,
    String locale = 'vn',
    String currencyCode = 'VND',
    required String txnRef,
    String orderInfo = 'Pay Order',
    required double amount,
    required String returnUrl,
    required String ipAdress,
    String? createAt,
    String? expireAt,
    String orderType = "other",
    required String vnpayHashKey,
    VNPayHashType vnPayHashType = VNPayHashType.HMACSHA512,
  }) {
    final params = <String, dynamic>{
      'vnp_Version': version,
      'vnp_Command': command,
      'vnp_TmnCode': tmnCode,
      'vnp_Locale': locale,
      'vnp_CurrCode': currencyCode,
      'vnp_TxnRef': txnRef,
      'vnp_OrderInfo': orderInfo,
      'vnp_OrderType': orderType,
      'vnp_Amount': (amount * 100).toStringAsFixed(0),
      'vnp_ReturnUrl': returnUrl,
      'vnp_IpAddr': ipAdress,
      'vnp_CreateDate': createAt ??
          DateFormat('yyyyMMddHHmmss').format(DateTime.now()).toString(),
      'vnp_ExpireDate': expireAt ??
          DateFormat('yyyyMMddHHmmss')
              .format(DateTime.now().add(Duration(minutes: 5)))
              .toString(),
    };
    var sortedParam = _sortParams(params);
    final hashDataBuffer = StringBuffer();
    sortedParam.forEach((key, value) {
      hashDataBuffer.write(key);
      hashDataBuffer.write('=');
      hashDataBuffer.write(value);
      hashDataBuffer.write('&');
    });
    String hashData =
        hashDataBuffer.toString().substring(0, hashDataBuffer.length - 1);
    String query = Uri(queryParameters: sortedParam).query;
    
    String vnpSecureHash = "";

    if (vnPayHashType == VNPayHashType.SHA256) {
      List<int> bytes = utf8.encode(vnpayHashKey + hashData.toString());
      vnpSecureHash = sha256.convert(bytes).toString();
    } else {
      vnpSecureHash = Hmac(sha512, utf8.encode(vnpayHashKey))
          .convert(utf8.encode(query))
          .toString();
    }
    String paymentUrl = "$url?$query&vnp_SecureHash=$vnpSecureHash";
    return paymentUrl;
  }

  void show({
    required String paymentUrl,
    Function(Map<String, dynamic>)? onPaymentSuccess,
    Function(Map<String, dynamic>)? onPaymentError,
    Function()? onWebPaymentComplete,
  }) async {
    if (kIsWeb) {
      js.context.callMethod('open', [paymentUrl, '_self']);
      // await launchUrlString(
      //   paymentUrl,
      //   webOnlyWindowName: '_self',
      // );
      if (onWebPaymentComplete != null) {
        onWebPaymentComplete();
      }
    } else {
      final FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
      flutterWebviewPlugin.onUrlChanged.listen((url) async {
        if (url.contains('vnp_ResponseCode')) {
          final params = Uri.parse(url).queryParameters;
          if (params['vnp_ResponseCode'] == '00') {
            if (onPaymentSuccess != null) {
              onPaymentSuccess(params);
            }
          } else {
            if (onPaymentError != null) {
              onPaymentError(params);
            }
          }
          flutterWebviewPlugin.close();
        }
      });
      flutterWebviewPlugin.launch(paymentUrl);
    }
  }
}
