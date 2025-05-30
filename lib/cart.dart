import 'package:flutter/material.dart';
import 'dashboard.dart'; // Ensure Product class is here
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'checkout.dart';
import 'buyersorder.dart';


class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> syncedCartItems = [];
  Set<int> selectedCartIds = {};

  @override
  void initState() {
    super.initState();
    fetchCartFromBackend();
  }

  Future<void> fetchCartFromBackend() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/get_cart?user_id=${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['cart'];

        setState(() {
          syncedCartItems = items.map((item) {
            return {
             'product': Product(
  id: item['product_id'],
  name: item['product_name'] ?? 'Unnamed',
  stock: item['stock'] ?? 100,
  price: item['product_price'].toString(),
  imageUrl: "http://10.0.2.2:5000/static/img/${item['product_img'] ?? 'placeholder.png'}",
  purchaseCount: item['purchase_count'] ?? 0,
  averageRating: (item['average_rating'] ?? 0).toDouble(),
  description: item['description'] ?? 'No description',
  sellerName: item['seller_name'] ?? 'Unknown Seller', //nabago ni karil
  shopName: item['shop_name'] ?? 'Unknown Shop', //nabago ni karil
),

              'quantity': int.tryParse(item['product_qty'].toString()) ?? 0,
              'cart_id': item['cart_id'],
            };
          }).toList();
        });
      } else {
        print('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  Future<void> removeFromCart(int cartId) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/remove_from_cart');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cart_id': cartId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item removed from cart")));
      fetchCartFromBackend();
    } else {
      print("Error removing item: ${response.body}");
    }
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/update_cart_quantity');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cart_id': cartId, 'quantity': newQuantity}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quantity updated')));
      await fetchCartFromBackend();
    } else {
      print("Error updating quantity: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = syncedCartItems;
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));

    double selectedTotal = 0;
    for (var item in cartItems) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      final cartId = item['cart_id'] as int;
      if (selectedCartIds.contains(cartId)) {
        selectedTotal += (double.tryParse(product.price) ?? 0) * quantity;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Shopping Cart"),
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(Icons.shopping_cart),
                if (cartCount > 0)
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.pink[50],
      body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuyersOrderScreen(userId: widget.userId),
              ),
            );
          },
          icon: Icon(Icons.receipt_long),
          label: Text("View All Orders"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    ),
    Expanded(
      child: cartItems.isEmpty
          ? Center(child: Text("Your cart is empty."))
          : RefreshIndicator(
              onRefresh: fetchCartFromBackend,
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final product = item['product'] as Product;
                  final quantity = item['quantity'] as int;
                  final cartId = item['cart_id'] as int;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: selectedCartIds.contains(cartId),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedCartIds.add(cartId);
                                } else {
                                  selectedCartIds.remove(cartId);
                                }
                              });
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 60),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("₱${product.price} x $quantity", style: TextStyle(fontSize: 14)),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: quantity > 1
                                          ? () => updateQuantity(cartId, quantity - 1)
                                          : null,
                                    ),
                                    Text('$quantity', style: TextStyle(fontSize: 16)),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline),
                                      onPressed: () => updateQuantity(cartId, quantity + 1),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => removeFromCart(cartId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    ),
  ],
),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: selectedCartIds.isEmpty
              ? null
              : () async {
                  final selectedItems = syncedCartItems
                      .where((item) => selectedCartIds.contains(item['cart_id']))
                      .toList();

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        selectedItems: selectedItems,
                        userId: widget.userId,
                      ),
                    ),
                  );

                  if (result == true) {
                    await fetchCartFromBackend(); // Refresh after placing order
                    selectedCartIds.clear(); // Clear selection
                  }
                },
          child: Text(
            "Checkout ₱${selectedTotal.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
