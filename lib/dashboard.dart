import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart.dart';
import 'CategoryScreen.dart';
import 'profile.dart';  
import 'checkout.dart';

class Product {
  final int id;
  final String name;
  final int stock;
  final String price;
  final String imageUrl;
  final int purchaseCount;
  final double averageRating;
  final String description;
  final String sellerName; //nabago ni karil
  final String shopName; //nabago ni karil

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.imageUrl,
    required this.purchaseCount,
    required this.averageRating,
    required this.description,
    required this.sellerName, //nabago ni karil
    required this.shopName, //nabago ni karil
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed',
      stock: json['stock'] ?? 0,
      price: json['price']?.toString() ?? '0.00',
      imageUrl: "http://10.0.2.2:5000/static/img/${json['image'] ?? 'placeholder.png'}",
      purchaseCount: json['purchase_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      description: json['description'] ?? 'No description',
      sellerName: json['seller_name'] ?? 'Unknown Seller', //nabago ni karil
      shopName: json['shop_name'] ?? 'Unknown Shop', //nabago ni karil
    );
  }
}


class Dashboard extends StatefulWidget {
  final int userId;
  const Dashboard({super.key, required this.userId});
  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  Map<String, List<Product>> categories = {};
  bool isLoading = true;
  int _selectedIndex = 0;
  final List<ScrollController> _controllers = [];

  late int userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    fetchProducts(); // now uses the correct userId
  }


  Future<Map<String, dynamic>> fetchProductStats(int productId) async {
  final url = Uri.parse('http://10.0.2.2:5000/api/product_stats/$productId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {'purchase_count': 0, 'average_rating': 0.0};
  }
}


  

  Future<void> fetchProducts() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/customer_db');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final categoriesData = jsonBody['categories'] as Map<String, dynamic>;

        Map<String, List<Product>> loadedCategories = {};
        categoriesData.forEach((category, products) {
          List<Product> productList = [];
          for (var product in products) {
            productList.add(Product.fromJson(product));
          }
          loadedCategories[category] = productList;
        });

        setState(() {
          categories = loadedCategories;
          _controllers.clear();
          for (int i = 0; i < categories.length; i++) {
            _controllers.add(ScrollController());
          }
          isLoading = false;
        });
      } else {
        print('Failed to load products: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> addToCartOnServer(Product product, int quantity) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/add_to_cart');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId, // dynamic user ID dito
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

  // Inside showProductDetails function (just the dialog)
void showProductDetails(Product product) async {
  int quantity = 1;
  final stats = await fetchProductStats(product.id);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.all(16),
            title: Center(
              child: Text(
                product.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      product.imageUrl,
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 12),

                  Text("₱${product.price}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),

                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 18, color: Colors.grey[700]),
                      SizedBox(width: 4),
                      Text("Stock: ${product.stock}"),
                      SizedBox(width: 16),
                      Icon(Icons.shopping_bag, size: 18, color: Colors.grey[700]),
                      SizedBox(width: 4),
                      Text("Sold: ${stats['purchase_count']}"),
                    ],
                  ),

                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber),
                      SizedBox(width: 4),
                      Text("Rating: ${stats['average_rating']}"),
                    ],
                  ),

                  SizedBox(height: 12),
                  Divider(),
                  Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Divider(),

                  SizedBox(height: 4),
                  Text("Seller: ${product.sellerName}", style: TextStyle(color: Colors.purple)),
                  Text("Shop: ${product.shopName}", style: TextStyle(color: Colors.purple)),

                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                      ),
                      Text('$quantity', style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (quantity < product.stock) setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await addToCartOnServer(product, quantity);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen(userId: userId)),
                  );
                },
                icon: Icon(Icons.shopping_cart),
                label: Text("Add to Cart"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:5000/api/place_order_now'),
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Order placed successfully!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to place order")),
                    );
                  }
                },
                icon: Icon(Icons.flash_on),
                label: Text("Buy Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(userId: userId),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryScreen(categories: categories, userId: userId),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: Column(
          children: [
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', width: 60,),
                  SizedBox(
  width: 252, // o gamitin ang Expanded kung gusto mo ng full width
  child: TextField(
    decoration: InputDecoration(
      hintText: "Search",
      fillColor: Colors.white,
      filled: true,
      prefixIcon: Icon(Icons.search, size: 20), // optional: maliit na icon
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // adjust height
      isDense: true, // makes the field more compact
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    style: TextStyle(fontSize: 14), // optional: adjust text size
  ),
),
                  IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
                ],
              ),
            )
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: (categories.isEmpty || _controllers.length != categories.length)
                    ? [SizedBox()]
                    : categories.entries.toList().asMap().entries.map((entry) {
                        final idx = entry.key;
                        final category = entry.value.key;
                        final products = entry.value.value;
                        final controller = _controllers[idx];

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                    offset: Offset(0, 3))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sectionTitle(category),
                                SizedBox(height: 8),
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: 220,
                                      child: ListView.separated(
                                        controller: controller,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: products.length,
                                        separatorBuilder: (_, __) =>
                                            SizedBox(width: 12),
                                        itemBuilder: (context, i) {
                                          final product = products[i];
                                          return Container(
                                            width: 140,
                                            decoration: BoxDecoration(
                                              color: Colors.pink[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.pink.shade100),
                                            ),
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    product.imageUrl,
                                                    width: 120,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 50),
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  product.name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  '₱${product.price}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700]),
                                                ),
                                                Spacer(),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      showProductDetails(
                                                          product),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.pink,
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: Size(60, 28),
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                  ),
                                                  child: Text("VIEW",
                                                      style: TextStyle(
                                                          fontSize: 11)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Left arrow
                                    Positioned(
                                      left: 0,
                                      top: 80,
                                      bottom: 80,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.animateTo(
                                            (controller.offset - 160)
                                                .clamp(0.0,
                                                    controller.position.maxScrollExtent),
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.ease,
                                          );
                                        },
                                        child: Container(
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.chevron_left,
                                              size: 28, color: Colors.pink),
                                        ),
                                      ),
                                    ),
                                    // Right arrow
                                    Positioned(
                                      right: 0,
                                      top: 80,
                                      bottom: 80,
                                      child: GestureDetector(
                                        onTap: () {
                                          controller.animateTo(
                                            (controller.offset + 160)
                                                .clamp(0.0,
                                                    controller.position.maxScrollExtent),
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.ease,
                                          );
                                        },
                                        child: Container(
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.chevron_right,
                                              size: 28, color: Colors.pink),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: 20, bottom: 10),
      child: Text(
        title,
        style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink[700]),
      ),
    );
  }
}
