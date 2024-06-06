// screens/delivery_method_screen.dart
import 'package:flutter/material.dart';
import 'delivery_address_picker_screen.dart';

class DeliveryMethodScreen extends StatefulWidget {
  final String currentDeliveryMethod;
  final ValueChanged<String> onDeliveryMethodChanged;
  final ValueChanged<Map<String, dynamic>> onDeliveryDetailsChanged;

  DeliveryMethodScreen({
    required this.currentDeliveryMethod,
    required this.onDeliveryMethodChanged,
    required this.onDeliveryDetailsChanged,
  });

  @override
  _DeliveryMethodScreenState createState() => _DeliveryMethodScreenState();
}

class _DeliveryMethodScreenState extends State<DeliveryMethodScreen> {
  String? _selectedDeliveryMethod;
  String? _selectedDeliveryService;
  String deliveryAddress = '';

  @override
  void initState() {
    super.initState();
    _selectedDeliveryMethod = widget.currentDeliveryMethod;
  }

  void _handleDeliveryServiceChange(String service) {
    setState(() {
      _selectedDeliveryService = service;
    });
  }

  void _pickDeliveryAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryAddressPickerScreen(
          deliveryMethod: _selectedDeliveryMethod!,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        deliveryAddress = result['location'].toString();
        widget.onDeliveryDetailsChanged({
          'method': _selectedDeliveryMethod,
          'service': _selectedDeliveryService,
          'address': deliveryAddress,
          'apartment': result['apartment'] ?? '',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Delivery method', style: TextStyle(fontSize: 20)),
            ),
            Divider(color: Colors.grey),
            _buildDeliveryOption(
              'Pick up at a store',
              'Free',
              _selectedDeliveryMethod == 'Pick up at a store',
              () {
                setState(() {
                  _selectedDeliveryMethod = 'Pick up at a store';
                  _selectedDeliveryService = null;
                  widget.onDeliveryMethodChanged(_selectedDeliveryMethod!);
                });
              },
            ),
            Divider(color: Colors.grey),
            _buildDeliveryOption(
              'Pick up at a delivery point',
              'Carrier tariffs',
              _selectedDeliveryMethod == 'Pick up at a delivery point',
              () {
                setState(() {
                  _selectedDeliveryMethod = 'Pick up at a delivery point';
                  _selectedDeliveryService = null;
                  widget.onDeliveryMethodChanged(_selectedDeliveryMethod!);
                });
              },
            ),
            Divider(color: Colors.grey),
            _buildDeliveryOption(
              'Home delivery',
              'Carrier tariffs',
              _selectedDeliveryMethod == 'Home delivery',
              () {
                setState(() {
                  _selectedDeliveryMethod = 'Home delivery';
                  _selectedDeliveryService = null;
                  widget.onDeliveryMethodChanged(_selectedDeliveryMethod!);
                });
              },
            ),
            Divider(color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Delivery service', style: TextStyle(fontSize: 20)),
            ),
            Divider(color: Colors.grey),
            if (_selectedDeliveryMethod == 'Pick up at a store') ...[
              _buildServiceOption(
                'Pick up at a store',
                'Free',
                _selectedDeliveryService == 'Pick up at a store',
                () => _handleDeliveryServiceChange('Pick up at a store'),
              ),
              // Add more store options if needed
            ] else if (_selectedDeliveryMethod ==
                'Pick up at a delivery point') ...[
              _buildServiceOption(
                'Pick up at a delivery point',
                'Carrier tariffs',
                _selectedDeliveryService == 'Pick up at a delivery point',
                () => _handleDeliveryServiceChange('Pick up at a delivery point'),
              ),
              // Add more delivery point options if needed
            ] else if (_selectedDeliveryMethod == 'Home delivery') ...[
              _buildServiceOption(
                'Glovo',
                'Carrier tariffs',
                _selectedDeliveryService == 'Glovo',
                () => _handleDeliveryServiceChange('Glovo'),
              ),
              // Add more home delivery options if needed
            ],
            if (_selectedDeliveryService != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _pickDeliveryAddress,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pick the delivery address',
                          style: TextStyle(color: Colors.black)),
                      Icon(Icons.arrow_forward_ios, color: Colors.black),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(
      String title, String price, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(price),
      trailing: Radio(
        value: isSelected,
        groupValue: true,
        onChanged: (value) {
          onTap();
        },
        activeColor: Colors.pink[800],
      ),
      onTap: onTap,
    );
  }

  Widget _buildServiceOption(
      String title, String price, bool isSelected, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(price),
          trailing: Radio(
            value: isSelected,
            groupValue: true,
            onChanged: (value) {
              onTap();
            },
            activeColor: Colors.pink[800],
          ),
          onTap: onTap,
        ),
        Divider(color: Colors.grey),
      ],
    );
  }
}
