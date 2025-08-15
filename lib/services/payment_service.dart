import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PaymentService {
  final BuildContext context;
  final Function(int) updateBalance;
  final Function(bool) setLoading;
  final NumberFormat numberFormat;
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];

  PaymentService({
    required this.context,
    required this.updateBalance,
    required this.setLoading,
    required this.numberFormat,
  });

  void initializeInAppPurchases() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase Error: $error'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    const Set<String> _kProductIds = {'coins_1000', 'coins_5000', 'coins_10000'};
    final response = await _inAppPurchase.queryProductDetails(_kProductIds);
    if (response.notFoundIDs.isNotEmpty) return;
    _products = response.productDetails;
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        setLoading(true);
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        await _verifyAndDeliverProduct(purchase);
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${purchase.error?.message}')),
        );
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchase) async {
    int coinsToAdd = 0;
    switch (purchase.productID) {
      case 'coins_1000': coinsToAdd = 1000; break;
      case 'coins_5000': coinsToAdd = 5000; break;
      case 'coins_10000': coinsToAdd = 10000; break;
    }
    
    updateBalance(coinsToAdd);
    setLoading(false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully purchased ${numberFormat.format(coinsToAdd)} coins!')),
    );
  }

  void processPayment({
    required Map<String, dynamic> gift,
    required String recipientName,
    required int currentBalance,
    required String recipientId,
    String? postId,
  }) {
    setLoading(true);

    // Here you would typically make an API call to your backend
    // to process the gift sending and deduct coins
    Future.delayed(const Duration(seconds: 2), () {
      setLoading(false);
      final newBalance = currentBalance - (gift['coins'] as int);
      updateBalance(newBalance < 0 ? 0 : newBalance);
      
      // You would also send recipientId and postId to your backend
      // to associate the gift with the correct user and post
      if (postId != null) {
        print('Gift sent to post $postId');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${gift['name']} sent to $recipientName!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: const Text('You don\'t have enough coins. Would you like to buy more?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showPaymentOptions();
            },
            child: const Text('Buy Coins'),
          ),
        ],
      ),
    );
  }

  void showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Buy Coins', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const Divider(height: 1),
            if (_products.isEmpty)
              const Padding(padding: EdgeInsets.all(16.0), child: Text('Loading products...'))
            else
              ..._products.map((product) => ListTile(
                title: Text(product.title),
                subtitle: Text(product.description),
                trailing: Text(product.price),
                onTap: () {
                  Navigator.pop(context);
                  _buyProduct(product);
                },
              )).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _buyProduct(ProductDetails product) async {
    setLoading(true);
    try {
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to purchase: ${e.toString()}')),
      );
    }
  }

  void dispose() => _subscription.cancel();
}