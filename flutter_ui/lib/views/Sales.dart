import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ui/core/services/api_service.dart';
import 'package:flutter_ui/views/invoice_page.dart';

final List<Map<String, dynamic>> localSales = [];

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  Map<String, dynamic>? product;
  bool isLoading = true;

  final formKey = GlobalKey<FormState>();

  final buyerName = TextEditingController();
  final buyerPhone = TextEditingController();
  final buyerAddress = TextEditingController();

  final discountController = TextEditingController(text: "0");
  double discount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final productId = ModalRoute.of(context)?.settings.arguments as int?;
    if (productId != null) {
      _loadProduct(productId);
    }
  }

  Future<void> _loadProduct(int id) async {
    try {
      final response = await ApiService().getBuyPhoneById(id);
      setState(() {
        product = response['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    discountController.addListener(() {
      final parsed = double.tryParse(discountController.text) ?? 0;
      setState(() => discount = parsed);
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

  void _completeSale(double total, double price) {
    final sale = {
      "product_id": product?["id"],
      "model": product?["model"],
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load product")),
      );
    }

    final double price = double.tryParse(
          (product?["resell_price"] ?? product?["selling_price"] ?? "0")
              .toString(),
        ) ??
        0;

    final double safeDiscount = discount.clamp(0, price);
    final double total = price - safeDiscount;

    ImageProvider img;
    if (product?["imageBytes"] is Uint8List) {
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
            const Text('Buyer Information',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _fieldForm(buyerName, 'Name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Name required" : null),
            _fieldForm(buyerPhone, 'Phone',
                isNumber: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Phone required" : null),
            _fieldForm(buyerAddress, 'Address',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Address required" : null),

            const SizedBox(height: 20),
            const Text('Product',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2B3A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: img, fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?["model"] ?? "Unknown",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if ((product?["color"] ?? "").toString().isNotEmpty)
                          Text("Color: ${product?["color"]}",
                              style:
                                  const TextStyle(color: Colors.grey)),
                        if ((product?["storage"] ?? "").toString().isNotEmpty)
                          Text("Storage: ${product?["storage"]}",
                              style:
                                  const TextStyle(color: Colors.grey)),
                        if ((product?["imei"] ?? "").toString().isNotEmpty)
                          Text("IMEI: ${product?["imei"]}",
                              style:
                                  const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('\$$price',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _fieldForm(discountController, "Discount",
                isNumber: true,
                validator: (v) {
                  final d = double.tryParse(v ?? "");
                  if (d == null) return "Invalid";
                  if (d < 0) return "No negative";
                  if (d > price) return "Too big";
                  return null;
                }),

            const SizedBox(height: 14),

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
                  Text("\$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
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

  Widget _fieldForm(TextEditingController c, String label,
      {bool isNumber = false, String? Function(String?)? validator}) {
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
