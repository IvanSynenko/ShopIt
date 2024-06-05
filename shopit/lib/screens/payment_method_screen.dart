// screens/payment_method_screen.dart
import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String currentPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;

  PaymentMethodScreen({
    required this.currentPaymentMethod,
    required this.onPaymentMethodChanged,
  });

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.currentPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Payment methods', style: TextStyle(fontSize: 20)),
          ),
          Divider(color: Colors.grey),
          _buildPaymentOption('Upon receipt'),
          Divider(color: Colors.grey),
          _buildPaymentOption('Now'),
          Divider(color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    return ListTile(
      title: Text(method),
      leading: Radio<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value;
            widget.onPaymentMethodChanged(_selectedPaymentMethod!);
          });
          Navigator.pop(context);
        },
        activeColor: Colors.purple,
      ),
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          widget.onPaymentMethodChanged(_selectedPaymentMethod!);
        });
        Navigator.pop(context);
      },
    );
  }
}
