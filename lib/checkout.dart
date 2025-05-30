import 'package:flutter/material.dart';
import 'dashboard.dart'; // Make sure Product class is imported
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buyersorder.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final int userId;

  const CheckoutScreen({super.key, required this.selectedItems, required this.userId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String shippingMethod = '10'; // Default: Door to Door
  final TextEditingController messageController = TextEditingController();
  final String address = "178, Kinilaw, Barangay Salac, Lumban, Laguna";

  double get subtotal {
    return widget.selectedItems.fold(0, (sum, item) {
      final product = item['product'] as Product;
      final qty = item['quantity'] as int;
      return sum + ((double.tryParse(product.price) ?? 0) * qty);
    });
  }

  double get shippingFee => shippingMethod == '10' ? 10.0 : 0.0;

  double get total => subtotal + shippingFee;

  Future<void> placeOrder() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/placed_order');

    final orderData = {
      "user_id": widget.userId,
      "order_address": address,
      "order_shipmethod": shippingMethod,
      "items": widget.selectedItems.map((item) {
        final product = item['product'] as Product;
        final qty = item['quantity'] as int;
        final price = double.tryParse(product.price) ?? 0;
        return {
          "product_id": product.id,
          "cart_id": item['cart_id'],
          "seller_id": 0,
          "order_image": product.imageUrl.split('/').last,
          "order_productname": product.name,
          "order_description": "No description",
          "order_price": price,
          "order_qty": qty,
          "order_totalprice": price * qty,
        };
      }).toList(),
      "order_message": messageController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order placed successfully!')),
          );

          // Go to BuyersOrder screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BuyersOrderScreen(userId: widget.userId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to place order: ${resBody['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Ordered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink)),
              Divider(),
              ...widget.selectedItems.map((item) {
                final product = item['product'] as Product;
                final qty = item['quantity'] as int;
                final price = double.tryParse(product.price) ?? 0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(product.imageUrl, width: 80, height: 80),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Price: ₱${price.toStringAsFixed(2)}'),
                          Text('Quantity: $qty'),
                          Text('Total: ₱${(price * qty).toStringAsFixed(2)}'),
                        ],
                      ),
                    )
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
              Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(address),
              SizedBox(height: 10),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Message for Seller',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text('Payment Method', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              Text('Cash On Delivery'),
              SizedBox(height: 20),
              Text('Shipping Method'),
              RadioListTile(
                title: Text('Door to Door Delivery ₱10'),
                value: '10',
                groupValue: shippingMethod,
                onChanged: (value) => setState(() => shippingMethod = value!),
              ),
              RadioListTile(
                title: Text('Self Pick-Up ₱0'),
                value: '0',
                groupValue: shippingMethod,
                onChanged: (value) => setState(() => shippingMethod = value!),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Merchandise Subtotal:'),
                  Text('₱${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shipping Total:'),
                  Text('₱${shippingFee.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₱${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text("Place Order", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
