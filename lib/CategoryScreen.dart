import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart.dart';
import 'dashboard.dart'; // For Product class

class CategoryScreen extends StatelessWidget {
  final Map<String, List<Product>> categories;
  final int userId;

  const CategoryScreen({
    super.key,
    required this.categories,
    required this.userId,
  });

  Future<void> addToCartOnServer(BuildContext context, Product product, int quantity) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/add_to_cart');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId,
          'product_id': product.id,
          'product_name': product.name,
          'product_price': product.price,
          'product_qty': quantity,
          'product_img': product.imageUrl.split('/').last,
        }),
      );
      if (response.statusCode == 200) {
        print("Product added to cart.");
      } else {
        print("Failed to add to cart. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending to server: $e");
    }
  }

  void showProductDetails(BuildContext context, Product product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.imageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Stock: ${product.stock} pcs'),
                  Text('Price: ₱${product.price}'),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                      ),
                      Text('$quantity', style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (quantity < product.stock) setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await addToCartOnServer(context, product, quantity);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(userId: userId),
                      ),
                    );
                  },
                  child: Text("Add to Cart"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.pink[50],
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: categories.entries.map((entry) {
          final categoryName = entry.key;
          final products = entry.value;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: ExpansionTile(
              title: Text(
                categoryName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.pink[700],
                ),
              ),
              children: products.map((product) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text("₱${product.price} • Stock: ${product.stock}"),
                    trailing: ElevatedButton(
                      onPressed: () => showProductDetails(context, product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text("VIEW", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
