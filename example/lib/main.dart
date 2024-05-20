import 'dart:developer' as dev;
import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({Key? key}) : super(key: key);

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  String responseCode = '';

  void onPayment() async {
    String baseUrl = html.window.location.origin;
    final paymentUrl = VNPAYFlutter.instance.generatePaymentUrl(
      url: 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
      version: '2.1.0',
      tmnCode: 'XXX',
      txnRef: DateTime.now().millisecondsSinceEpoch.toString(),
      orderInfo: 'Thanh toan don hang ${Random().nextInt(1000000)}',
      amount: 100000,
      returnUrl: baseUrl,
      ipAdress: '192.168.1.1',
      vnpayHashKey: 'XXX',
      vnPayHashType: VNPayHashType.HMACSHA512,
    );
    dev.log(paymentUrl);
    VNPAYFlutter.instance.show(
      paymentUrl: paymentUrl,
      onPaymentSuccess: (params) {
        dev.log("oke");
      },
      onPaymentError: (params) {
        dev.log("fail");
      },
      onWebPaymentComplete: () {
        dev.log("oke2");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Response Code: $responseCode'),
            TextButton(
              onPressed: onPayment,
              child: const Text('10.000VND'),
            ),
          ],
        ),
      ),
    );
  }
}
