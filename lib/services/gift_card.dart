import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GiftCard extends StatelessWidget {
  final String name;
  final double price;
  final IconData icon;
  final Color color;
  final int coins;
  final String currencySymbol;
  final NumberFormat numberFormat;
  final VoidCallback onTap;
  final bool isPurchased;
  final bool showPrice;
  final bool showCoins;
  final double iconSize;
  final double nameFontSize;
  final double priceFontSize;
  final double coinsFontSize;
  final Color? cardColor;
  final Color? purchasedTextColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? shadow;
  final Widget? customPurchasedIndicator;
  final Widget? customPriceWidget;
  final Widget? customCoinsWidget;

  const GiftCard({
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
    required this.coins,
    required this.currencySymbol,
    required this.numberFormat,
    required this.onTap,
    this.isPurchased = false,
    this.showPrice = true,
    this.showCoins = true,
    this.iconSize = 30.0,
    this.nameFontSize = 12.0,
    this.priceFontSize = 11.0,
    this.coinsFontSize = 11.0,
    this.cardColor,
    this.purchasedTextColor,
    this.padding = const EdgeInsets.all(8.0),
    this.borderRadius,
    this.shadow,
    this.customPurchasedIndicator,
    this.customPriceWidget,
    this.customCoinsWidget,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor ?? Colors.white,
      elevation: shadow != null ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius as BorderRadius? ?? BorderRadius.circular(10),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with customizable size
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 5),
              
              // Name with customizable font size
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: nameFontSize,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Price display - can be custom widget or default
              if (showPrice && !isPurchased)
                customPriceWidget ?? Text(
                  '$currencySymbol${numberFormat.format(price)}',
                  style: TextStyle(
                    color: Colors.green, 
                    fontSize: priceFontSize,
                  ),
                ),
              
              // Purchased indicator - can be custom widget or default
              if (isPurchased)
                customPurchasedIndicator ?? Text(
                  'Purchased',
                  style: TextStyle(
                    color: purchasedTextColor ?? Colors.blue, 
                    fontSize: priceFontSize,
                  ),
                ),
              const SizedBox(height: 4),
              
              // Coins display - can be custom widget or default
              if (showCoins)
                customCoinsWidget ?? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, 
                      size: coinsFontSize, 
                      color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '${numberFormat.format(coins)}',
                      style: TextStyle(
                        color: Colors.amber, 
                        fontSize: coinsFontSize,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}