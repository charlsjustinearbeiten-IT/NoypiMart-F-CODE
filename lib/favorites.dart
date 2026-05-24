import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  final Set<String> favorites;
  final void Function(String) onToggleFavorite;
  final void Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> allProducts;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.allProducts,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const String placeholderImage = 'images/products/kangkong.png';

  List<Map<String, dynamic>> get _favoriteProducts {
    return widget.allProducts
        .where((product) => widget.favorites.contains(product['name']))
        .map((product) {
      return {
        ...product,
        'image': product['image'] ?? placeholderImage,
      };
    }).toList();
  }

  String _getProductImage(Map<String, dynamic> product) {
    final image = product['image'];
    if (image != null && image is String && image.isNotEmpty) {
      return image;
    }
    return placeholderImage;
  }

  void _removeFromFavorites(String productName) {
    // ✅ Call parent toggle — snackbar is shown in home.dart, NOT here
    widget.onToggleFavorite(productName);
    setState(() {});
  }

  void _addProductToCart(Map<String, dynamic> product) {
    final productWithImage = {
      ...product,
      'image': _getProductImage(product),
    };

    // ✅ Call parent add to cart — snackbar is shown in home.dart, NOT here
    // ✅ Clear any existing snackbar first to prevent spam stacking
    ScaffoldMessenger.of(context).clearSnackBars();
    widget.onAddToCart(productWithImage);
  }

  @override
  Widget build(BuildContext context) {
    final favProducts = _favoriteProducts;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            if (favProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '${favProducts.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: favProducts.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 18),
                  const Text(
                    'Wala pang favorites!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'I-tap ang puso sa kahit anong produkto para idagdag dito.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            : GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: favProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final product = favProducts[index];
            final productName = product['name'] as String;
            final isFav = widget.favorites.contains(productName);
            final imagePath = _getProductImage(product);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: product['color'] as Color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 50,
                                  color: Colors.grey.shade500,
                                );
                              },
                            ),
                          ),
                        ),

                        // ❤️ Heart button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeFromFavorites(productName),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isFav ? Colors.red : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          product['weight'] as String,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product['price'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),

                            // ➕ Add to cart button
                            GestureDetector(
                              onTap: () => _addProductToCart(product),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
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
      ),
    );
  }
}