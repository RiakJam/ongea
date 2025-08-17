import 'package:flutter/material.dart';

class AdCard extends StatelessWidget {
  final String adText;
  final String imageUrl;

  const AdCard({
    Key? key,
    required this.adText,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full device width
      margin: EdgeInsets.symmetric(vertical: 4), // Keep vertical margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad image with "Ad" tag overlay
          Stack(
            children: [
              Image.network(
                imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/400x150.png?text=Test+Ad',
                height: 150,
                width: double.infinity, // Full width
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "sponsored",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Ad text
          Container(
            color: Colors.white, // Background for text area
            padding: EdgeInsets.all(12),
            width: double.infinity, // Full width
            child: Text(
              adText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}