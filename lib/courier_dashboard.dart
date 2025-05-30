import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

const String baseUrl = 'http://10.0.2.2:5000/api';

class CourierDashboard extends StatefulWidget {
  final int userId;
  final String? token;

  const CourierDashboard({super.key, required this.userId, this.token});

  @override
  _CourierDashboardState createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  String selectedTab = 'pickup';
  List<dynamic> orders = [];
  bool isLoading = false;
  String? errorMessage;

  final Map<String, IconData> tabIcons = {
    'pickup': Icons.assignment,
    'for_delivery': Icons.delivery_dining,
    'delivered': Icons.local_shipping,
    'ratings': Icons.star,
    'income': Icons.attach_money,
  };

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      orders = [];
    });

    final url = Uri.parse('$baseUrl/courier/orders/$selectedTab?user_id=${widget.userId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => orders = data);
      } else {
        setState(() => errorMessage = 'Failed to load data (${response.statusCode})');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void switchTab(String tab) {
    setState(() => selectedTab = tab);
    fetchOrders();

    if (tab == 'pickup') {
      fetchProcessedOrdersAndShowModal();
    }
  }

  Future<void> confirmAction(String message, Function onConfirm) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) onConfirm();
  }

  Future<void> markOrderDelivered(int orderId) async {
    final url = Uri.parse('$baseUrl/mark_for_delivery/$orderId');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as For Delivery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> markAsDelivered(int orderId) async {
    final url = Uri.parse('$baseUrl/mark_as_delivered/$orderId');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as delivered')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as delivered')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildTabButton(String tab, String label) {
    final isActive = selectedTab == tab;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => switchTab(tab),
        icon: Icon(tabIcons[tab], size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.pinkAccent : Colors.grey[300],
          foregroundColor: isActive ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    switch (selectedTab) {
      case 'pickup':
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: ListTile(
            title: Text(order['order_productname'] ?? 'Unknown item'),
            subtitle: Text('Qty: ${order['order_qty']} | ₱${order['order_totalprice']}'),
            trailing: ElevatedButton(
              onPressed: () => confirmAction(
                'Mark order as picked up?',
                () => markOrderDelivered(order['order_id']),
              ),
              child: Text('Pick-up'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        );

      case 'for_delivery':
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: ListTile(
            title: Text(order['order_productname'] ?? 'Unknown item'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${order['order_qty']} | ₱${order['order_totalprice']}'),
                SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () => confirmAction(
                    'Mark order as delivered?',
                    () => markAsDelivered(order['order_id']),
                  ),
                  child: Text('Delivered'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Order #: ${order['order_id']}'),
                Text(order['order_status'] ?? '', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );

      case 'delivered':
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: ListTile(
            title: Text(order['order_productname'] ?? 'Unknown item'),
            subtitle: Text('Qty: ${order['order_qty']} | ₱${order['order_totalprice']}'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Order #: ${order['order_id']}'),
                Text(order['order_shipmethod'] ?? '', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );

      case 'ratings':
  int rating = 0;
  var rawRating = order['rating'];
  if (rawRating is int) {
    rating = rawRating;
  } else if (rawRating is String) {
    rating = int.tryParse(rawRating) ?? 0;
  }

  return ListTile(
    title: Text('Order #${order['order_id']}'),
    subtitle: Text(order['order_productname'] ?? ''),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 20,
        );
      }),
    ),
  );


      case 'income':
        return ListTile(
          title: Text('Order #${order['order_id']}'),
          subtitle: Text('Date: ${order['received_date']}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${order['net_income']}'),
              Text(order['order_shipmethod'], style: TextStyle(fontSize: 12)),
            ],
          ),
        );

      default:
        return Container();
    }
  }

  Future<void> fetchProcessedOrdersAndShowModal() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/processed_orders'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => DraggableScrollableSheet(
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Processed Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: data['orders'].length,
                      itemBuilder: (context, index) {
                        final order = data['orders'][index];
                        return Card(
                          child: ListTile(
                            leading: Image.asset(
                              'assets/${order['order_image']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(order['order_productname']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Qty: ${order['order_qty']}'),
                                Text('Customer: ${order['f_name']} ${order['l_name']}'),
                                Text('Status: ${order['order_status']}'),
                              ],
                            ),
                            trailing: Text('₱${order['order_totalprice']}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch processed orders.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courier Dashboard'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                buildTabButton('pickup', 'Pick Up'),
                SizedBox(width: 8),
                buildTabButton('for_delivery', 'For Delivery'),
                SizedBox(width: 8),
                buildTabButton('delivered', 'Delivered'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                buildTabButton('ratings', 'Ratings'),
                SizedBox(width: 8),
                buildTabButton('income', 'Income'),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(errorMessage!),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: fetchOrders,
                              child: Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                        ? Center(child: Text('No data found.'))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) => buildOrderCard(orders[index]),
                          ),
          ),
        ],
      ),
    );
  }
}
