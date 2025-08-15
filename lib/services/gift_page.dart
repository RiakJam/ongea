import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'gift_card.dart';
import 'gift_data.dart';
import 'payment_service.dart';
import 'currency_service.dart';

class GiftPage extends StatefulWidget {
  final String recipientName;
  final String recipientAvatar;
  final String recipientId; // Changed from userId to be more explicit
  final String? postId;
  final Map<String, dynamic>? additionalData;

  const GiftPage({
    required this.recipientName,
    required this.recipientAvatar,
    required this.recipientId,
    this.postId,
    this.additionalData,
    Key? key,
  }) : super(key: key);

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> with SingleTickerProviderStateMixin {
  int userBalance = 0;
  late String currencySymbol;
  String currencyCode = 'USD';
  bool isLoading = false;
  late TabController _tabController;
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  
  late PaymentService _paymentService;
  late CurrencyService _currencyService;
  
  final Map<String, List<Map<String, dynamic>>> giftCategories = GiftData.giftCategories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: giftCategories.length, vsync: this);
    _loadUserBalance();
    
    _paymentService = PaymentService(
      context: context,
      updateBalance: _updateBalance,
      setLoading: _setLoading,
      numberFormat: _numberFormat,
    );
    
    _currencyService = CurrencyService(
      updateCurrency: _updateCurrency,
      numberFormat: _numberFormat,
    );
    
    _currencyService.detectCurrency();
    _paymentService.initializeInAppPurchases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) => setState(() => isLoading = loading);

  void _updateBalance(int newBalance) {
    setState(() => userBalance = newBalance);
    _saveUserBalance();
  }

  void _updateCurrency(String code, String symbol) {
    setState(() {
      currencyCode = code;
      currencySymbol = symbol;
    });
  }

  Future<void> _loadUserBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userBalance = prefs.getInt('userBalance') ?? 1000);
  }

  Future<void> _saveUserBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userBalance', userBalance);
  }

  void _purchaseGift(Map<String, dynamic> gift) {
    if (gift['price'] == 0.00) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${gift['name']} sent to ${widget.recipientName}!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (userBalance >= (gift['coins'] as int)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Gift', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(gift['icon'] as IconData, color: gift['color'] as Color, size: 40),
              const SizedBox(height: 16),
              Text(
                'Send ${gift['name']} to ${widget.recipientName} for $currencySymbol${_numberFormat.format(gift['price'])}?',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                '(${_numberFormat.format(gift['coins'])} coins)', 
                style: const TextStyle(color: Colors.amber),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.pop(context);
                _paymentService.processPayment(
                  gift: gift,
                  recipientName: widget.recipientName,
                  currentBalance: userBalance,
                  recipientId: widget.recipientId,
                  postId: widget.postId,
                );
              },
              child: const Text('Send Gift', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _paymentService.showInsufficientBalanceDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Send Gift to ${widget.recipientName}',
          style: const TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: giftCategories.keys.map((category) => Tab(
            text: category,
          )).toList(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.recipientAvatar),
                      radius: 25,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Send a gift to ${widget.recipientName}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: giftCategories.keys.map((category) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: giftCategories[category]!.length,
                      itemBuilder: (context, index) {
                        final gift = giftCategories[category]![index];
                        return GiftCard(
                          name: gift['name'] as String,
                          price: gift['price'] as double,
                          icon: gift['icon'] as IconData,
                          color: gift['color'] as Color,
                          coins: gift['coins'] as int,
                          currencySymbol: currencySymbol,
                          numberFormat: _numberFormat,
                          onTap: () => _purchaseGift(gift),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your balance: ${_numberFormat.format(userBalance)} coins',
                      style: const TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: _paymentService.showPaymentOptions,
                      child: const Text(
                        'Buy More Coins',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}