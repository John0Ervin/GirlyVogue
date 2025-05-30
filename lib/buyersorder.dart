import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyersOrderScreen extends StatefulWidget {
  final int userId;

  const BuyersOrderScreen({super.key, required this.userId});

  @override
  _BuyersOrderScreenState createState() => _BuyersOrderScreenState();
}

class _BuyersOrderScreenState extends State<BuyersOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> pendingOrders = [];
  List<dynamic> toDeliverOrders = [];
  List<dynamic> completedOrders = [];
  List<dynamic> cancelledOrders = [];

  Set<int> selectedPending = {};
  Set<int> selectedToDeliver = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final baseUrl = 'http://10.0.2.2:5000/api/orders?user_id=${widget.userId}';
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl&status=pending')),
        http.get(Uri.parse('$baseUrl&status=to_deliver')),
        http.get(Uri.parse('$baseUrl&status=completed')),
        http.get(Uri.parse('$baseUrl&status=cancelled')),
      ]);

      if (responses.every((res) => res.statusCode == 200)) {
        setState(() {
          pendingOrders = jsonDecode(responses[0].body)['orders'];
          toDeliverOrders = jsonDecode(responses[1].body)['orders'];
          completedOrders = jsonDecode(responses[2].body)['orders'];
          cancelledOrders = jsonDecode(responses[3].body)['orders'];
        });
      } else {
        print("Error loading orders.");
      }
    } catch (e) {
      print("Error fetching orders: $e");
    }
  }

  Future<void> cancelOrder(int orderId) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/cancel_order');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId}),
      );
      if (res.statusCode == 200) {
        await fetchOrders();
      } else {
        print("Cancel failed: ${res.body}");
      }
    } catch (e) {
      print("Cancel error: $e");
    }
  }

  Future<void> cancelSelectedOrders() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/cancel_order');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_ids': selectedPending.toList()}),
      );

      if (res.statusCode == 200) {
        selectedPending.clear();
        await fetchOrders();
      }
    } catch (e) {
      print("Cancel error: $e");
    }
  }

  Future<void> markOrdersAsCompleted(List<int> orderIds) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/mark_completed');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_ids': orderIds}),
      );
      if (res.statusCode == 200) {
        await fetchOrders();
      }
    } catch (e) {
      print("Complete error: $e");
    }
  }

  Future<void> submitRating(int orderId, int rating) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/submit_rating');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'rating': rating}),
      );
      if (res.statusCode == 200) {
        await fetchOrders();
      } else {
        print("Rating failed: ${res.body}");
      }
    } catch (e) {
      print("Rating error: $e");
    }
  }

  Widget buildOrderList(
    List<dynamic> orders, {
    bool withCheckbox = false,
    Set<int>? selectedSet,
    bool showCompleteButton = false,
    bool showCancelButton = false,
    bool allowRating = false,
  }) {
    return RefreshIndicator(
      onRefresh: fetchOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final orderId = order['order_id'];
          final imageUrl =
              "http://10.0.2.2:5000/static/img/${order['order_image']}";

          return Card(
            margin: EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (withCheckbox && selectedSet != null)
                        Checkbox(
                          value: selectedSet.contains(orderId),
                          onChanged: (value) {
                            setState(() {
                              value!
                                  ? selectedSet.add(orderId)
                                  : selectedSet.remove(orderId);
                            });
                          },
                        ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image,
                                size: 60, color: Colors.grey);
                          },
                        ),
                      ),
                    ],
                  ),
                  title: Text(order['order_productname']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${order['order_status']}"),
                      Text("Qty: ${order['order_qty']}"),
                      Text("Total: ₱${order['order_totalprice']}"),
                      if (allowRating)
                        order['rating'] != null
                            ? Row(
                                children: [
                                  Text("Rating: "),
                                  ...List.generate(
                                    order['rating'],
                                    (index) => Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                  )
                                ],
                              )
                            : RatingBar(
                                orderId: orderId,
                                onSubmitted: (rating) =>
                                    submitRating(orderId, rating),
                              ),
                    ],
                  ),
                ),
                if (showCancelButton)
                  ElevatedButton(
                    onPressed: () async {
                      await cancelOrder(orderId);
                    },
                    child: Text("Cancel Order"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                  ),
                if (showCompleteButton &&
                    order['order_status'] != 'Delivered')
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Waiting for courier to mark as delivered.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text("My Orders"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "To Deliver"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(children: [
            Expanded(
              child: buildOrderList(
                pendingOrders,
                withCheckbox: true,
                selectedSet: selectedPending,
                showCancelButton: true,
              ),
            ),
            if (selectedPending.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: cancelSelectedOrders,
                  child: Text("Cancel Selected Orders"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                ),
              ),
          ]),
          Column(children: [
            Expanded(
              child: buildOrderList(
                toDeliverOrders,
                withCheckbox: true,
                selectedSet: selectedToDeliver,
                showCompleteButton: true,
              ),
            ),
            if (selectedToDeliver.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: () async {
                    await markOrdersAsCompleted(
                        selectedToDeliver.toList());
                    selectedToDeliver.clear();
                  },
                  child: Text("Mark Selected as Completed"),
                ),
              )
          ]),
          buildOrderList(completedOrders, allowRating: true),
          buildOrderList(cancelledOrders),
        ],
      ),
    );
  }
}

class RatingBar extends StatefulWidget {
  final int orderId;
  final Function(int) onSubmitted;

  const RatingBar(
      {super.key, required this.orderId, required this.onSubmitted});

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => rating = index + 1),
            );
          }),
        ),
        ElevatedButton(
          onPressed: rating > 0 ? () => widget.onSubmitted(rating) : null,
          child: Text("Submit Rating"),
        )
      ],
    );
  }
}
