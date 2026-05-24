import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = [
      {'name': 'Fresh Carrots', 'price': '₱ 35', 'weight': '1 kg', 'color': Color(0xFFFFE0B2)},
      {'name': 'Red Apples', 'price': '₱ 80', 'weight': '500 g', 'color': Color(0xFFFFCDD2)},
      {'name': 'Spinach', 'price': '₱ 25', 'weight': '250 g', 'color': Color(0xFFC8E6C9)},
      {'name': 'Orange Juice', 'price': '₱ 55', 'weight': '1 L', 'color': Color(0xFFFFF9C4)},
      {'name': 'Grapes', 'price': '₱ 120', 'weight': '500 g', 'color': Color(0xFFE1BEE7)},
      {'name': 'Banana', 'price': '₱ 30', 'weight': '1 kg', 'color': Color(0xFFFFF9C4)},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shop',
          style: TextStyle(color: Colors.black87, fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: product['color'] as Color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Center(child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey.shade500)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] as String,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      Text(product['weight'] as String,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(product['price'] as String,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}