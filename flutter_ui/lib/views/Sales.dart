import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ui/views/invoice_page.dart';


/// ---------------------------------------------------------------------------
/// LOCAL SALES STORAGE (TEMPORARY)
/// ---------------------------------------------------------------------------
/// This list stores all completed sales in memory (RAM).
/// If you close the app, the data will be lost.
///
/// API Integration Later:
/// - Instead of saving here, you will POST the sale data to your backend
///   (example: POST /sales)
/// - You can also save locally using SQLite/Hive/SharedPreferences if needed
final List<Map<String, dynamic>> localSales = [];

/// ---------------------------------------------------------------------------
/// SalePage
/// ---------------------------------------------------------------------------
/// This page completes a sale for a selected product.
/// The product is passed from InventoryPage using:
///
/// Navigator.pushNamed(context, '/sale', arguments: productMap);
///
/// The product map should contain at least:
/// - model or name
/// - selling_price or sellPrice
/// - optional: imei, storage, color
/// - optional: imageBytes (Uint8List) for displaying the selected image
class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  /// Selected product passed from InventoryPage
  Map<String, dynamic>? product;

  /// Form key validates buyer inputs and discount input
  final formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // BUYER INPUT CONTROLLERS
  // ---------------------------------------------------------------------------
  final buyerName = TextEditingController();
  final buyerPhone = TextEditingController();
  final buyerAddress = TextEditingController();

  // ---------------------------------------------------------------------------
  // DISCOUNT INPUT (LIVE UPDATED)
  // ---------------------------------------------------------------------------
  final discountController = TextEditingController(text: "0");

  /// Current discount numeric value (used in total calculations)
  double discount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Reads the product arguments once, safely
    product ??=
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void initState() {
    super.initState();

    /// Any time the user updates the discount input, we update the UI
    discountController.addListener(() {
      final parsed = double.tryParse(discountController.text) ?? 0;
      setState(() {
        discount = parsed;
      });
    });
  }

  @override
  void dispose() {
    buyerName.dispose();
    buyerPhone.dispose();
    buyerAddress.dispose();
    discountController.dispose();
    super.dispose();
  }

  /// ---------------------------------------------------------------------------
  /// COMPLETE SALE (LOCAL)
  /// ---------------------------------------------------------------------------
  /// This function creates a sale object and stores it inside localSales list.
  ///
  /// API Integration Later:
  /// - POST request to backend: POST /sales
  /// - Backend should:
  ///   1) create a sale record (customer, totals)
  ///   2) create sale_items records
  ///   3) reduce product quantity in inventory
  void _completeSale(double total, double price) {
    final sale = {
      "product_id": product?["id"],
      "model": product?["name"] ?? product?["model"] ?? "Unknown",
      "imei": product?["imei"],
      "storage": product?["storage"],
      "color": product?["color"],
      "price": price,
      "discount": discount,
      "total": total,
      "buyer_name": buyerName.text.trim(),
      "buyer_phone": buyerPhone.text.trim(),
      "buyer_address": buyerAddress.text.trim(),
      "imageBytes": product?["imageBytes"],
      "created_at": DateTime.now().toIso8601String(),
    };

    localSales.add(sale);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => InvoicePage(sale: sale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// If product was not passed correctly
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Sale')),
        body: const Center(
          child: Text(
            "No product selected.\nGo back and choose a product from inventory.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // PRICE CALCULATION
    // -------------------------------------------------------------------------
    /// Handles both possible keys: sellPrice or selling_price
    final double price =
        double.tryParse(
          (product?["sellPrice"] ?? product?["selling_price"] ?? "0")
              .toString(),
        ) ??
        0;

    /// Clamp discount so it never goes negative or above price
    final double safeDiscount = discount.clamp(0, price);

    /// Total after discount
    final double total = price - safeDiscount;

    // -------------------------------------------------------------------------
    // IMAGE PROVIDER LOGIC
    // -------------------------------------------------------------------------
    /// product can contain:
    /// - "image" as ImageProvider
    /// - OR "imageBytes" as Uint8List
    /// - OR none (fallback to placeholder)
    ImageProvider img;

    if (product?["image"] is ImageProvider) {
      img = product!["image"];
    } else if (product?["imageBytes"] is Uint8List) {
      img = MemoryImage(product!["imageBytes"]);
    } else {
      img = const AssetImage("assets/placeholder.png");
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==========================================================
            // BUYER SECTION
            // ==========================================================
            const Text(
              'Buyer Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _fieldForm(
              buyerName,
              'Name',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Buyer name is required";
                }
                if (v.trim().length < 3) {
                  return "Name must be at least 3 characters";
                }
                return null;
              },
            ),

            _fieldForm(
              buyerPhone,
              'Phone',
              isNumber: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Buyer phone is required";
                }
                if (v.trim().length < 8) {
                  return "Phone number is too short";
                }
                return null;
              },
            ),

            _fieldForm(
              buyerAddress,
              'Address',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Buyer address is required";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // PRODUCT CARD SECTION
            // ==========================================================
            const Text(
              'Product',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2B3A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // IMAGE PREVIEW
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: img, fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // PRODUCT DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?["name"]?.toString() ??
                              product?["model"]?.toString() ??
                              "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        if ((product?["color"] ?? "").toString().isNotEmpty)
                          Text(
                            "Color: ${product?["color"]}",
                            style: const TextStyle(color: Colors.grey),
                          ),

                        if ((product?["storage"] ?? "").toString().isNotEmpty)
                          Text(
                            "Storage: ${product?["storage"]}",
                            style: const TextStyle(color: Colors.grey),
                          ),

                        if ((product?["imei"] ?? "").toString().isNotEmpty)
                          Text(
                            "IMEI: ${product?["imei"]}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),

                  // PRODUCT PRICE
                  Text(
                    '\$$price',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // DISCOUNT SECTION
            // ==========================================================
            /// Discount changes update total in real time because of listener
            _fieldForm(
              discountController,
              "Discount",
              isNumber: true,
              validator: (v) {
                final d = double.tryParse(v ?? "");
                if (d == null) return "Discount must be a number";
                if (d < 0) return "Discount cannot be negative";
                if (d > price) return "Discount cannot be higher than price";
                return null;
              },
            ),

            const SizedBox(height: 14),

            // ==========================================================
            // TOTAL SECTION
            // ==========================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2B3A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 18)),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // COMPLETE SALE BUTTON
            // ==========================================================
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  /// Validate buyer fields + discount field
                  final isValid = formKey.currentState!.validate();
                  if (!isValid) return;

                  /// Store sale locally (later replaced by API call)
                  _completeSale(total, price);
                },
                child: const Text('Complete Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// FIELD BUILDER (UI HELPER)
  /// ---------------------------------------------------------------------------
  /// Centralizes all TextFormField styling so your UI is consistent
  Widget _fieldForm(
    TextEditingController c,
    String label, {
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFF1C2B3A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }
}
