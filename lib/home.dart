import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile.dart';
import 'favorites.dart';
import 'cart.dart';
import 'orders.dart';

// ── Product image paths ──────────────────────────────────────────────────────
const Map<String, String> productImages = {
  // Bigas
  'Sinandomeng Rice': 'images/products/sinandomeng.png',
  'Dinorado Rice': 'images/products/dinorado.png',
  'NFA Rice': 'images/products/nfa_rice.png',
  'Milagrosa Rice': 'images/products/milagrosa.png',
  'Jasmine Rice': 'images/products/jasmine.png',
  'Malagkit Rice': 'images/products/malagkit.png',
  // Gulay
  'Kangkong': 'images/products/kangkong.png',
  'Sitaw': 'images/products/sitaw.png',
  'Ampalaya': 'images/products/ampalaya.png',
  'Talong': 'images/products/talong.png',
  'Kalabasa': 'images/products/kalabasa.png',
  'Pechay': 'images/products/pechay.png',
  // Prutas
  'Orange': 'images/products/orange.png',
  'Pakwan': 'images/products/pakwan.png',
  'Mangga': 'images/products/mangga.png',
  'Langka': 'images/products/langka.png',
  'Mansanas': 'images/products/mansanas.png',
  'Ubas': 'images/products/ubas.png',
  // De Lata
  'Ligo Sardinas': 'images/products/ligo.png',
  '555 Sardinas': 'images/products/555.png',
  'Argentina Corned Beef': 'images/products/argentina.png',
  'CDO Corned Beef': 'images/products/cdo.png',
  'Purefoods Liver Spread': 'images/products/purefoods.png',
  'Spam': 'images/products/spam.png',
  // Karne
  'Liempo': 'images/products/liempo.png',
  'Manok (Whole)': 'images/products/chicken.png',
  'Kasim': 'images/products/kasim.png',
  'Ground Pork': 'images/products/ground_pork.png',
  'Chicken Breast': 'images/products/chicken_breast.png',
  'Pork Ribs': 'images/products/pork_ribs.png',
  // Isda
  'Bangus': 'images/products/bangus.png',
  'Tilapia': 'images/products/tilapia.png',
  'Galunggong': 'images/products/galunggong.png',
  'Dalagang Bukid': 'images/products/dalagang_bukid.png',
  'Lapu-Lapu': 'images/products/lapu.png',
  'Dilis': 'images/products/dilis.png',
  // Sangkap
  'Bawang': 'images/products/bawang.png',
  'Sibuyas': 'images/products/sibuyas.png',
  'Kamatis': 'images/products/kamatis.png',
  'Bagoong': 'images/products/bagoong.png',
  'Patis (Datu Puti)': 'images/products/patis.png',
  'Toyo (Datu Puti)': 'images/products/toyo.png',
  // Inumin
  'Zesto Juice': 'images/products/zesto.png',
  'Milo Sachet': 'images/products/milo.png',
  'Nescafe 3-in-1': 'images/products/nescafe.png',
  'C2 Apple': 'images/products/c2.png',
  'Coca-Cola': 'images/products/coke.png',
  'Tang Juice': 'images/products/tang.png',
};

String getProductImage(String productName) {
  return productImages[productName] ?? 'images/products/kangkong.png';
}

Map<String, dynamic> addImageToProduct(Map<String, dynamic> product) {
  final productName = product['name'] as String;
  return {
    ...product,
    'image': getProductImage(productName),
  };
}

class HomeScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const HomeScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final Set<String> _favorites = {};
  final List<Map<String, dynamic>> _cartItems = [];

  int get _cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Map<String, dynamic> _cartItemForFirestore(Map<String, dynamic> item) {
    return {
      'name': item['name'],
      'price': item['price'],
      'weight': item['weight'],
      'image': item['image'],
      'quantity': item['quantity'],
      'colorValue': (item['color'] as Color).value,
    };
  }

  Map<String, dynamic> _cartItemFromFirestore(Map<String, dynamic> item) {
    final productName = item['name'] as String;
    return {
      'name': productName,
      'price': item['price'],
      'weight': item['weight'],
      'image': item['image'] ?? getProductImage(productName),
      'quantity': item['quantity'] ?? 1,
      'color': Color(item['colorValue'] ?? 0xFFC8E6C9),
    };
  }

  Future<void> _loadUserSavedData() async {
    final docRef = _userDoc;
    if (docRef == null) return;

    try {
      final doc = await docRef.get();
      final data = doc.data();
      if (data == null) return;

      final savedFavorites = data['favorites'];
      final savedCartItems = data['cartItems'];

      if (!mounted) return;

      setState(() {
        _favorites.clear();
        if (savedFavorites is List) {
          _favorites.addAll(savedFavorites.map((item) => item.toString()));
        }

        _cartItems.clear();
        if (savedCartItems is List) {
          _cartItems.addAll(
            savedCartItems
                .whereType<Map>()
                .map((item) => _cartItemFromFirestore(Map<String, dynamic>.from(item))),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final docRef = _userDoc;
    if (docRef == null) return;
    await docRef.set({'favorites': _favorites.toList()}, SetOptions(merge: true));
  }

  Future<void> _saveCart() async {
    final docRef = _userDoc;
    if (docRef == null) return;
    await docRef.set(
      {'cartItems': _cartItems.map(_cartItemForFirestore).toList()},
      SetOptions(merge: true),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserSavedData();
  }

  // ✅ Fixed: clearSnackBars before showing to prevent duplicate/spam
  void _toggleFavorite(String name) {
    final bool alreadyFavorite = _favorites.contains(name);

    setState(() {
      if (alreadyFavorite) {
        _favorites.remove(name);
      } else {
        _favorites.add(name);
      }
    });

    _saveFavorites();

    ScaffoldMessenger.of(context).clearSnackBars(); // ✅ dismiss current first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyFavorite
              ? '$name removed from favorites'
              : '$name added to favorites',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: alreadyFavorite ? Colors.red.shade400 : Colors.green,
      ),
    );
  }

  int _priceToInt(String price) {
    return int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  // ✅ Fixed: clearSnackBars before showing to prevent duplicate/spam
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final productName = product['name'] as String;
      final existingIndex = _cartItems.indexWhere((item) => item['name'] == productName);

      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] =
            (_cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        _cartItems.add({
          'name': product['name'],
          'price': product['price'],
          'weight': product['weight'],
          'color': product['color'],
          'image': getProductImage(product['name'] as String),
          'quantity': 1,
        });
      }
    });

    _saveCart();

    ScaffoldMessenger.of(context).clearSnackBars(); // ✅ dismiss current first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product['name']} added to cart!',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _increaseCartItem(String name) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['name'] == name);
      if (index >= 0) {
        _cartItems[index]['quantity'] = (_cartItems[index]['quantity'] as int) + 1;
      }
    });
    _saveCart();
  }

  void _decreaseCartItem(String name) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['name'] == name);
      if (index >= 0) {
        final quantity = _cartItems[index]['quantity'] as int;
        if (quantity > 1) {
          _cartItems[index]['quantity'] = quantity - 1;
        } else {
          _cartItems.removeAt(index);
        }
      }
    });
    _saveCart();
  }

  void _deleteCartItem(String name) {
    setState(() {
      _cartItems.removeWhere((item) => item['name'] == name);
    });
    _saveCart();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _checkoutCart(Map<String, String> deliveryInfo) async {
    if (_cartItems.isEmpty) return;

    int total = 0;
    int totalItems = 0;
    final details = StringBuffer();

    for (final item in _cartItems) {
      final quantity = item['quantity'] as int;
      final price = _priceToInt(item['price'] as String);
      final subtotal = price * quantity;

      total += subtotal;
      totalItems += quantity;
      details.writeln('${item['name']} - ${item['price']} x $quantity = ₱ $subtotal');
    }

    details.writeln('');
    details.writeln('Total Items: $totalItems');
    details.writeln('Total Amount: ₱ $total');

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to place an order.', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final orderDate = _formatDate(now);
    final orderId = '#ORD-${now.millisecondsSinceEpoch}';

    // ✅ Use exactly what user typed — not re-fetched from Firestore
    final customerName = deliveryInfo['name'] ?? '';
    final customerPhone = deliveryInfo['phone'] ?? '';
    final customerAddress = deliveryInfo['address'] ?? '';

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': uid,
        'orderId': orderId,
        'date': orderDate,
        'items': totalItems,
        'total': '₱ $total',
        'status': 'Processing',
        'details': details.toString(),
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _cartItems.clear();
        _selectedIndex = 3;
      });

      await _saveCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e', style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        fullName: widget.fullName,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      FavoritesScreen(
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
        allProducts: _HomeTabState.allProductsWithImages,
      ),
      CartScreen(
        cartItems: _cartItems,
        onAddQuantity: _increaseCartItem,
        onDecreaseQuantity: _decreaseCartItem,
        onDeleteItem: _deleteCartItem,
        onCheckout: _checkoutCart,
      ),
      const OrdersScreen(),
      ProfileScreen(fullName: widget.fullName, email: widget.email),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              label: 'Cart',
              icon: Badge(
                isLabelVisible: _cartItemCount > 0,
                label: Text('$_cartItemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                backgroundColor: Colors.red,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: _cartItemCount > 0,
                label: Text('$_cartItemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                backgroundColor: Colors.red,
                child: const Icon(Icons.shopping_cart),
              ),
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final String fullName;
  final Set<String> favorites;
  final void Function(String) onToggleFavorite;
  final void Function(Map<String, dynamic>) onAddToCart;

  const _HomeTab({
    required this.fullName,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedCategory = 'Bigas';
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _allProductsList = [
    {'name': 'Sinandomeng Rice',      'price': '₱ 1120', 'weight': 'per kg',   'color': Color(0xFFFFF8E1)},
    {'name': 'Dinorado Rice',         'price': '₱ 1200', 'weight': 'per kg',   'color': Color(0xFFFFF3E0)},
    {'name': 'NFA Rice',              'price': '₱ 875',  'weight': 'per kg',   'color': Color(0xFFFFFDE7)},
    {'name': 'Milagrosa Rice',        'price': '₱ 1100', 'weight': '1 pack',   'color': Color(0xFFFFECB3)},
    {'name': 'Jasmine Rice',          'price': '₱ 1300', 'weight': '1 pack',   'color': Color(0xFFFFF9C4)},
    {'name': 'Malagkit Rice',         'price': '₱ 1450', 'weight': '6 pcs',    'color': Color(0xFFFFF8E1)},
    {'name': 'Kangkong',              'price': '₱ 15',   'weight': '1 bundle', 'color': Color(0xFFC8E6C9)},
    {'name': 'Sitaw',                 'price': '₱ 20',   'weight': '250 g',    'color': Color(0xFFA5D6A7)},
    {'name': 'Ampalaya',              'price': '₱ 30',   'weight': '500 g',    'color': Color(0xFFB2DFDB)},
    {'name': 'Talong',                'price': '₱ 20',   'weight': '500 g',    'color': Color(0xFFCE93D8)},
    {'name': 'Kalabasa',              'price': '₱ 45',   'weight': '500 g',    'color': Color(0xFFFFCC80)},
    {'name': 'Pechay',                'price': '₱ 10',   'weight': '1 bundle', 'color': Color(0xFFC8E6C9)},
    {'name': 'Orange',                'price': '₱ 15',   'weight': '1 kg',     'color': Color(0xFFFFF9C4)},
    {'name': 'Pakwan',                'price': '₱ 55',   'weight': 'per kg',   'color': Color(0xFFC8E6C9)},
    {'name': 'Mangga',                'price': '₱ 18',   'weight': '1 kg',     'color': Color(0xFFFFE082)},
    {'name': 'Langka',                'price': '₱ 65',   'weight': 'per kg',   'color': Color(0xFFFFCC80)},
    {'name': 'Mansanas',              'price': '₱ 15',   'weight': '500 g',    'color': Color(0xFFDCEDC8)},
    {'name': 'Ubas',                  'price': '₱ 60',   'weight': '500 g',    'color': Color(0xFFFFF9C4)},
    {'name': 'Ligo Sardinas',         'price': '₱ 24',   'weight': '155 g',    'color': Color(0xFFB0BEC5)},
    {'name': '555 Sardinas',          'price': '₱ 26',   'weight': '155 g',    'color': Color(0xFFCFD8DC)},
    {'name': 'Argentina Corned Beef', 'price': '₱ 42',   'weight': '260 g',    'color': Color(0xFFBDBDBD)},
    {'name': 'CDO Corned Beef',       'price': '₱ 55',   'weight': '200 g',    'color': Color(0xFFB0BEC5)},
    {'name': 'Purefoods Liver Spread','price': '₱ 36',   'weight': '165 g',    'color': Color(0xFFD7CCC8)},
    {'name': 'Spam',                  'price': '₱ 285',  'weight': '340 g',    'color': Color(0xFFCFD8DC)},
    {'name': 'Liempo',                'price': '₱ 400',  'weight': 'per kg',   'color': Color(0xFFFFCDD2)},
    {'name': 'Manok (Whole)',         'price': '₱ 380',  'weight': 'per kg',   'color': Color(0xFFFFE0B2)},
    {'name': 'Kasim',                 'price': '₱ 370',  'weight': 'per kg',   'color': Color(0xFFFFCDD2)},
    {'name': 'Ground Pork',           'price': '₱ 260',  'weight': 'per kg',   'color': Color(0xFFFFCDD2)},
    {'name': 'Chicken Breast',        'price': '₱ 240',  'weight': 'per kg',   'color': Color(0xFFFFF9C4)},
    {'name': 'Pork Ribs',             'price': '₱ 310',  'weight': 'per kg',   'color': Color(0xFFFFE0B2)},
    {'name': 'Bangus',                'price': '₱ 180',  'weight': 'per kg',   'color': Color(0xFFB3E5FC)},
    {'name': 'Tilapia',               'price': '₱ 130',  'weight': 'per kg',   'color': Color(0xFFB2EBF2)},
    {'name': 'Galunggong',            'price': '₱ 160',  'weight': 'per kg',   'color': Color(0xFFB3E5FC)},
    {'name': 'Dalagang Bukid',        'price': '₱ 350',  'weight': 'per kg',   'color': Color(0xFFB2EBF2)},
    {'name': 'Lapu-Lapu',             'price': '₱ 280',  'weight': 'per kg',   'color': Color(0xFFE1F5FE)},
    {'name': 'Dilis',                 'price': '₱ 320',  'weight': 'per kg',   'color': Color(0xFFFFCDD2)},
    {'name': 'Bawang',                'price': '₱ 15',   'weight': '100 g',    'color': Color(0xFFFFF9C4)},
    {'name': 'Sibuyas',               'price': '₱ 18',   'weight': '100 g',    'color': Color(0xFFFFCDD2)},
    {'name': 'Kamatis',               'price': '₱ 20',   'weight': '250 g',    'color': Color(0xFFFFCDD2)},
    {'name': 'Bagoong',               'price': '₱ 35',   'weight': '250 g',    'color': Color(0xFFFFCC80)},
    {'name': 'Patis (Datu Puti)',     'price': '₱ 28',   'weight': '350 ml',   'color': Color(0xFFFFF9C4)},
    {'name': 'Toyo (Datu Puti)',      'price': '₱ 25',   'weight': '350 ml',   'color': Color(0xFFD7CCC8)},
    {'name': 'Zesto Juice',           'price': '₱ 12',   'weight': '250 ml',   'color': Color(0xFFFFE082)},
    {'name': 'Milo Sachet',           'price': '₱ 8',    'weight': '1 sachet', 'color': Color(0xFFD7CCC8)},
    {'name': 'Nescafe 3-in-1',        'price': '₱ 10',   'weight': '1 sachet', 'color': Color(0xFFBCAAA4)},
    {'name': 'C2 Apple',              'price': '₱ 25',   'weight': '500 ml',   'color': Color(0xFFD7CCC8)},
    {'name': 'Coca-Cola',             'price': '₱ 35',   'weight': '500 ml',   'color': Color(0xFFC8E6C9)},
    {'name': 'Tang Juice',            'price': '₱ 8',    'weight': '1 sachet', 'color': Color(0xFFFFF9C4)},
  ];

  static List<Map<String, dynamic>> get allProductsWithImages {
    return _allProductsList.map(addImageToProduct).toList();
  }

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'Bigas',   'icon': Icons.rice_bowl_outlined,   'color': Color(0xFFFF9800)},
    {'label': 'Gulay',   'icon': Icons.eco,                  'color': Color(0xFF4CAF50)},
    {'label': 'Prutas',  'icon': Icons.apple,                'color': Color(0xFFE91E63)},
    {'label': 'De Lata', 'icon': Icons.inventory_2_outlined, 'color': Color(0xFF607D8B)},
    {'label': 'Karne',   'icon': Icons.dinner_dining,        'color': Color(0xFFF44336)},
    {'label': 'Isda',    'icon': Icons.set_meal,             'color': Color(0xFF2196F3)},
    {'label': 'Sangkap', 'icon': Icons.spa_outlined,         'color': Color(0xFF795548)},
    {'label': 'Inumin',  'icon': Icons.local_drink_outlined, 'color': Color(0xFF00BCD4)},
  ];

  final Map<String, List<Map<String, dynamic>>> _productsByCategory = {
    'Bigas':   _allProductsList.sublist(0,  6).map(addImageToProduct).toList(),
    'Gulay':   _allProductsList.sublist(6,  12).map(addImageToProduct).toList(),
    'Prutas':  _allProductsList.sublist(12, 18).map(addImageToProduct).toList(),
    'De Lata': _allProductsList.sublist(18, 24).map(addImageToProduct).toList(),
    'Karne':   _allProductsList.sublist(24, 30).map(addImageToProduct).toList(),
    'Isda':    _allProductsList.sublist(30, 36).map(addImageToProduct).toList(),
    'Sangkap': _allProductsList.sublist(36, 42).map(addImageToProduct).toList(),
    'Inumin':  _allProductsList.sublist(42, 48).map(addImageToProduct).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final firstName = widget.fullName.split(' ').first;
    final allCategoryProducts = _productsByCategory[_selectedCategory] ?? [];

    final products = _searchQuery.isEmpty
        ? allCategoryProducts
        : allProductsWithImages
        .where((p) => (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Greeting + Search ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.green,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Magandang Araw, $firstName!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                    ),
                    const Text(
                      'Ano ang hanap mo ngayon?',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Maghanap ng produkto...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins', fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Banner ─────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(
                      'images/banner.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.green.shade100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 40, color: Colors.green.shade300),
                              const SizedBox(height: 8),
                              Text('NoyPiMart Banner', style: TextStyle(fontFamily: 'Poppins', color: Colors.green.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Shop by Category ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text('Shop by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.black87)),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['label'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade200, width: isSelected ? 2 : 1),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : cat['color'] as Color, size: 24),
                            const SizedBox(height: 5),
                            Text(cat['label'] as String, style: TextStyle(fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Section title ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Text(
                      _searchQuery.isNotEmpty ? 'Search Results' : _selectedCategory,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                      child: Text('${products.length} items', style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: Colors.green.shade700)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Empty search state ─────────────────────────────────────────────
            if (products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Walang nahanap para sa "$_searchQuery"',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 13), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Product Grid ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = products[index];
                    final productName = product['name'] as String;
                    final isFav = widget.favorites.contains(productName);
                    final imagePath = product['image'] as String;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
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
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(
                                      imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => widget.onToggleFavorite(productName),
                                    child: Container(
                                      width: 30, height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
                                      ),
                                      child: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 16, color: isFav ? Colors.red : Colors.grey.shade400),
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
                                Text(productName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                                Text(product['weight'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade500)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(product['price'] as String, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                    GestureDetector(
                                      onTap: () => widget.onAddToCart(product),
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
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
                  childCount: products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}