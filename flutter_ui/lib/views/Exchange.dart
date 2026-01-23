import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui/views/exchange_invoice_page.dart';


/// --------------------------------------------
/// ExchangePage (LOCAL VERSION)
/// --------------------------------------------
/// This page handles phone exchange workflow locally (no API).
///
/// Current behavior:
/// 1) User enters customer information
/// 2) User enters incoming phone (customer phone) information
/// 3) Incoming phone can be added locally into inventoryPhones list
/// 4) User searches for a phone from current inventoryPhones list
/// 5) User selects the phone that will be given to the customer
/// 6) Confirm exchange validates the form and confirms selection
///
/// Image behavior:
/// - Incoming phone image is OPTIONAL (not required)
///
/// API integration later:
/// - Load inventoryPhones from backend (GET /products)
/// - Add incoming phone to backend inventory (POST /products)
/// - Save exchange transaction (POST /exchanges)
class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  /// Global form key used to validate all form inputs in the page
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==========================================================
  // SECTION 1: Customer inputs
  // ==========================================================
  /// These fields represent the customer info (the person exchanging)
  final TextEditingController personName = TextEditingController();
  final TextEditingController personPhone = TextEditingController();
  final TextEditingController personAddress = TextEditingController();

  // ==========================================================
  // SECTION 2: Incoming phone inputs
  // ==========================================================
  /// These fields represent the phone the customer is bringing in
  final TextEditingController incomingName = TextEditingController();
  final TextEditingController incomingModel = TextEditingController();
  final TextEditingController incomingBrand = TextEditingController();
  final TextEditingController incomingImei = TextEditingController();
  final TextEditingController incomingStorage = TextEditingController();
  final TextEditingController incomingColor = TextEditingController();
  final TextEditingController incomingBuyPrice = TextEditingController();
  final TextEditingController incomingSellPrice = TextEditingController();

  /// Incoming phone image stored as bytes (works on Flutter Web and Mobile)
  /// This is optional and can be left empty.
  Uint8List? incomingImageBytes;

  /// Local brands list.
  /// API integration later:
  /// - Replace this list by calling GET /brands
  final List<String> brands = [
    'Apple',
    'Samsung',
    'Xiaomi',
    'Huawei',
    'Oppo',
    'Realme',
    'Google',
    'Nokia',
    'LG',
    'Sony',
  ];

  // ==========================================================
  // SECTION 3: Inventory search + selection
  // ==========================================================
  /// Search controller for inventory phones
  final TextEditingController inventorySearch = TextEditingController();

  /// Current search query used for filtering inventory
  String query = "";

  /// Local inventory phones list (phones you already own in your shop)
  ///
  /// API integration later:
  /// - Replace this list using GET /products
  /// - Show the real database products
  final List<Map<String, dynamic>> inventoryPhones = [
    {
      "model": "iPhone 15 Pro",
      "brand": "Apple",
      "imei": "1111222233334444",
      "storage": "256GB",
      "color": "Black",
      "selling_price": 999,
      "imageBytes": null,
    },
    {
      "model": "Samsung S24 Ultra",
      "brand": "Samsung",
      "imei": "9999888877776666",
      "storage": "512GB",
      "color": "Gray",
      "selling_price": 1199,
      "imageBytes": null,
    },
  ];

  /// Selected phone from inventory that will be given to the customer
  Map<String, dynamic>? selectedPhone;

  @override
  void dispose() {
    // Customer
    personName.dispose();
    personPhone.dispose();
    personAddress.dispose();

    // Incoming phone
    incomingName.dispose();
    incomingModel.dispose();
    incomingBrand.dispose();
    incomingImei.dispose();
    incomingStorage.dispose();
    incomingColor.dispose();
    incomingBuyPrice.dispose();
    incomingSellPrice.dispose();

    // Inventory Search
    inventorySearch.dispose();

    super.dispose();
  }

  // ==========================================================
  // IMAGE PICKER (LOCAL)
  // ==========================================================
  /// Picks incoming phone image as bytes
  /// Works on Flutter Web because we use `result.files.single.bytes`
  ///
  /// API integration later:
  /// - This image can be uploaded as MultipartFile (POST /products)
  Future<void> _pickIncomingImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        incomingImageBytes = result.files.single.bytes!;
      });
    }
  }

  // ==========================================================
  // INVENTORY SEARCH FILTER (LOCAL)
  // ==========================================================
  /// Filters inventoryPhones locally based on the search query.
  ///
  /// API integration later:
  /// - Replace this by GET /products/search?q=...
  List<Map<String, dynamic>> get filteredInventory {
    if (query.trim().isEmpty) return inventoryPhones;

    final q = query.toLowerCase();
    return inventoryPhones.where((p) {
      final model = (p["model"] ?? "").toString().toLowerCase();
      final imei = (p["imei"] ?? "").toString().toLowerCase();
      final brand = (p["brand"] ?? "").toString().toLowerCase();
      final storage = (p["storage"] ?? "").toString().toLowerCase();
      final color = (p["color"] ?? "").toString().toLowerCase();

      return model.contains(q) ||
          imei.contains(q) ||
          brand.contains(q) ||
          storage.contains(q) ||
          color.contains(q);
    }).toList();
  }

  // ==========================================================
  // ADD INCOMING PHONE TO INVENTORY (LOCAL)
  // ==========================================================
  /// Adds the incoming phone into inventoryPhones list locally.
  ///
  /// Important:
  /// - Image is optional
  /// - Form validation must pass
  ///
  /// API integration later:
  /// - Replace this by POST /products (incoming phone)
  void _addIncomingPhoneToInventory() {
    if (!formKey.currentState!.validate()) return;

    final buy = double.tryParse(incomingBuyPrice.text.trim()) ?? 0;
    final sell = double.tryParse(incomingSellPrice.text.trim()) ?? 0;

    final incomingPhone = {
      "model": incomingModel.text.trim(),
      "brand": incomingBrand.text.trim(),
      "imei": incomingImei.text.trim(),
      "storage": incomingStorage.text.trim(),
      "color": incomingColor.text.trim(),
      "purchase_price": buy,
      "selling_price": sell,
      "quantity": 1,

      // Local image bytes stored directly in memory
      "imageBytes": incomingImageBytes,
    };

    setState(() {
      inventoryPhones.insert(0, incomingPhone);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Incoming phone added to inventory")),
    );
  }

  // ==========================================================
  // CONFIRM EXCHANGE (LOCAL)
  // ==========================================================
  /// Confirms the exchange locally.
  /// Validation rules:
  /// - Form must be valid
  /// - User must select a phone from inventory
  ///
  /// API integration later:
  /// - POST /exchanges
  /// - Update inventory quantities
  void _confirmExchange() {
    if (!formKey.currentState!.validate()) return;

    if (selectedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a phone from inventory first")),
      );
      return;
    }

    final exchangeData = {
      "customer_name": personName.text.trim(),
      "customer_phone": personPhone.text.trim(),
      "customer_address": personAddress.text.trim(),

      "incoming_phone": {
        "model": incomingModel.text.trim(),
        "brand": incomingBrand.text.trim(),
        "imei": incomingImei.text.trim(),
        "storage": incomingStorage.text.trim(),
        "color": incomingColor.text.trim(),
        "selling_price": double.tryParse(incomingSellPrice.text.trim()) ?? 0,
        "imageBytes": incomingImageBytes,
      },

      "outgoing_phone": selectedPhone,

      "created_at": DateTime.now().toIso8601String(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExchangeInvoicePage(exchange: exchangeData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredInventory;

    final incomingPreviewImage = incomingImageBytes != null
        ? MemoryImage(incomingImageBytes!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Phone Exchange")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================================
          // SECTION A: Customer + Incoming phone Form
          // ==========================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B3A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Customer Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Customer validators
                  _field(
                    personName,
                    "Name",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (v.trim().length < 3) return "Name too short";
                      return null;
                    },
                  ),
                  _field(
                    personPhone,
                    "Phone",
                    isNumber: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (v.trim().length < 8) return "Phone too short";
                      return null;
                    },
                  ),
                  _field(
                    personAddress,
                    "Address",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),

                  const Divider(height: 28),

                  const Text(
                    "Incoming Phone (Customer Phone)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Image pick is optional
                  GestureDetector(
                    onTap: _pickIncomingImage,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1A25),
                        borderRadius: BorderRadius.circular(12),
                        image: incomingPreviewImage != null
                            ? DecorationImage(
                                image: incomingPreviewImage,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: incomingPreviewImage == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 40),
                                  SizedBox(height: 6),
                                  Text("Tap to pick image (optional)"),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _field(
                    incomingName,
                    "Phone Name",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),
                  _field(
                    incomingModel,
                    "Model",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (v.trim().length < 2) return "Model too short";
                      return null;
                    },
                  ),

                  // Brand dropdown
                  DropdownButtonFormField(
                    decoration: _decoration("Brand"),
                    items: brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => incomingBrand.text = v ?? "",
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  const SizedBox(height: 12),

                  _field(
                    incomingColor,
                    "Color",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),

                  _field(
                    incomingImei,
                    "IMEI (16 digits)",
                    isNumber: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      if (v.trim().length != 16)
                        return "IMEI must be 16 digits";
                      return null;
                    },
                  ),

                  _field(
                    incomingStorage,
                    "Storage",
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),

                  _field(
                    incomingBuyPrice,
                    "Buy Price",
                    isNumber: true,
                    validator: (v) {
                      final n = double.tryParse(v ?? "");
                      if (n == null) return "Must be a number";
                      if (n <= 0) return "Must be > 0";
                      return null;
                    },
                  ),
                  _field(
                    incomingSellPrice,
                    "Sell Price",
                    isNumber: true,
                    validator: (v) {
                      final sell = double.tryParse(v ?? "");
                      final buy = double.tryParse(incomingBuyPrice.text) ?? 0;

                      if (sell == null) return "Must be a number";
                      if (sell <= 0) return "Must be > 0";
                      if (buy > 0 && sell < buy) {
                        return "Sell price can't be < Buy price";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // Add incoming phone locally
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Incoming Phone to Inventory"),
                      onPressed: _addIncomingPhoneToInventory,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==========================================================
          // SECTION B: Choose phone from inventory
          // ==========================================================
          const Text(
            "Choose a Phone From Your Inventory",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: inventorySearch,
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: "Search by model / brand / IMEI / color...",
              filled: true,
              fillColor: const Color(0xFF1C2B3A),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Inventory list (local)
          if (list.isEmpty)
            const Center(
              child: Text(
                "No phones found in inventory.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...list.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2B3A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text("${p['model']} - ${p['storage']}"),
                  subtitle: Text("IMEI: ${p['imei']} | Color: ${p['color']}"),
                  trailing: Text("\$${p['selling_price']}"),
                  onTap: () => setState(() => selectedPhone = p),
                ),
              );
            }),

          const SizedBox(height: 18),

          // ==========================================================
          // SECTION C: Selected phone details preview
          // ==========================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B3A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: selectedPhone == null
                ? const Center(
                    child: Text(
                      "No phone selected yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Row(
                    children: [
                      // image
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: selectedPhone!["imageBytes"] != null
                                ? MemoryImage(selectedPhone!["imageBytes"])
                                : const AssetImage("assets/placeholder.png")
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPhone!["model"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Brand: ${selectedPhone!["brand"]}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "Color: ${selectedPhone!["color"]}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "IMEI: ${selectedPhone!["imei"]}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "Storage: ${selectedPhone!["storage"]}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // price
                      Text(
                        "\$${selectedPhone!["selling_price"]}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ==========================================================
          // SECTION D: Confirm Exchange
          // ==========================================================
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: selectedPhone == null ? null : _confirmExchange,
              child: const Text("Confirm Exchange"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // UI Helper Widgets
  // ==========================================================
  /// A reusable TextFormField builder with consistent styling
  Widget _field(
    TextEditingController c,
    String label, {
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: _decoration(label),
        validator:
            validator ?? (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  /// Shared decoration styling
  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF0E1A25),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
