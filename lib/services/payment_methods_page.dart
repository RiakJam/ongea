import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatefulWidget {
  @override
  _PaymentMethodsPageState createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<Map<String, String>> _paymentMethods = [
    {
      'type': 'Visa',
      'details': '•••• 4242',
      'expiry': '05/25',
    },
  ];

  /// Function to open Add Payment Method Dialog
  void _addPaymentMethod() {
    TextEditingController typeController = TextEditingController();
    TextEditingController detailsController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    bool isPayPal = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Add Payment Method'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: typeController,
                      decoration: InputDecoration(labelText: 'Payment Type (e.g., Visa, Bank, PayPal)'),
                      onChanged: (value) {
                        setStateDialog(() {
                          isPayPal = value.toLowerCase() == 'paypal';
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(labelText: 'Details (e.g., •••• 1234, Email)'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: expiryController,
                      enabled: !isPayPal,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        hintText: isPayPal ? 'Not required for PayPal' : '',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text('Add'),
                  onPressed: () {
                    if (typeController.text.isNotEmpty && detailsController.text.isNotEmpty) {
                      setState(() {
                        _paymentMethods.add({
                          'type': typeController.text,
                          'details': detailsController.text,
                          'expiry': isPayPal ? '' : expiryController.text,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Function to edit an existing payment method
  void _editPaymentMethod(int index) {
    TextEditingController typeController =
        TextEditingController(text: _paymentMethods[index]['type']);
    TextEditingController detailsController =
        TextEditingController(text: _paymentMethods[index]['details']);
    TextEditingController expiryController =
        TextEditingController(text: _paymentMethods[index]['expiry']);
    bool isPayPal = _paymentMethods[index]['type']!.toLowerCase() == 'paypal';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Payment Method'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: typeController,
                      decoration: InputDecoration(labelText: 'Payment Type'),
                      onChanged: (value) {
                        setStateDialog(() {
                          isPayPal = value.toLowerCase() == 'paypal';
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(labelText: 'Details'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: expiryController,
                      enabled: !isPayPal,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        hintText: isPayPal ? 'Not required for PayPal' : '',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text('Save'),
                  onPressed: () {
                    setState(() {
                      _paymentMethods[index] = {
                        'type': typeController.text,
                        'details': detailsController.text,
                        'expiry': isPayPal ? '' : expiryController.text,
                      };
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Delete payment method
  void _deletePaymentMethod(int index) {
    setState(() {
      _paymentMethods.removeAt(index);
    });
  }

  /// Get icon based on payment type
  Icon _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Icon(Icons.credit_card, color: Colors.blue);
      case 'bank account':
      case 'bank':
        return Icon(Icons.account_balance, color: Colors.green);
      case 'paypal':
        return Icon(Icons.payment, color: Colors.orange);
      default:
        return Icon(Icons.attach_money, color: Colors.purple);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payment Methods', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _paymentMethods.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                var payment = _paymentMethods[index];
                return ListTile(
                  leading: _getIcon(payment['type'] ?? ''),
                  title: Text(payment['type'] ?? '',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${payment['details']}'
                    '${payment['expiry']!.isNotEmpty ? " | Expires ${payment['expiry']}" : ""}',
                    style: TextStyle(color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.black),
                        onPressed: () => _editPaymentMethod(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePaymentMethod(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Payment Method'),
                onPressed: _paymentMethods.isEmpty ? _addPaymentMethod : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
