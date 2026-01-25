import 'package:flutter/material.dart';
import 'package:flutter_ui/views/DashBoard.dart';
import 'package:flutter_ui/views/Exchange.dart';
import 'package:flutter_ui/views/History.dart';
import 'package:flutter_ui/views/Login.dart';
import 'package:flutter_ui/views/Phone_Inventory.dart';
import 'package:flutter_ui/views/Sales.dart';
import 'package:flutter_ui/views/register.dart';

void main() {
  runApp(const ShopManagerApp());
}

class ShopManagerApp extends StatelessWidget {
  const ShopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop Manager',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1A25),
        primaryColor: Colors.blue,
      ),
      initialRoute: '/dashboard',
      routes: {
        '/login': (_) => Login(),
        '/register': (_) => Register() ,
        '/dashboard': (_) => DashboardPage(),
        '/inventory': (_) => InventoryPage(), 
        '/sale': (_) => SalePage(),
        '/exchange': (_) => ExchangePage(),
        '/history': (context) => HistoryPage(),
      },
    );
  }
}
