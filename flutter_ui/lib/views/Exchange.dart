import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui/views/exchange_invoice_page.dart';
import 'package:flutter_ui/core/services/api_service.dart';
import 'package:flutter_ui/core/config/api_config.dart'; 
import 'package:flutter_ui/core/services/auth_service.dart';


/// --------------------------------------------
/// ExchangePage (LOCAL VERSION) and now mister mechekak added the db version
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
   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController personName = TextEditingController();
  final TextEditingController personPhone = TextEditingController();
  final TextEditingController personAddress = TextEditingController();

  final TextEditingController incomingModel = TextEditingController();
  final TextEditingController incomingBrand = TextEditingController();
  final TextEditingController incomingImei = TextEditingController();
  final TextEditingController incomingStorage = TextEditingController();
  final TextEditingController incomingColor = TextEditingController();
  final TextEditingController incomingBuyPrice = TextEditingController();
  final TextEditingController incomingSellPrice = TextEditingController();
  Map<String, dynamic>? selectedPhone;
  final TextEditingController exchangePhoneController = TextEditingController();

// Future to fetch available phones that can be given to customer
  Future<List<Map<String, dynamic>>> availablePhonesFuture = Future.value([]) ;

  Uint8List? incomingImageBytes;
  /// Local brands list.
  final Future<List<Map<String, dynamic>>> brands = ApiService().getBrandsList();
  int? selectedBrandId;

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
  List<Map<String, dynamic>> inventoryPhones = [];


  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadInventoryFromApi();
    availablePhonesFuture = ApiService().getAvailableBuyPhones();
  }


  @override
  void dispose() {
    personName.dispose();
    personPhone.dispose();
    personAddress.dispose();
    incomingModel.dispose();
    incomingBrand.dispose();
    incomingImei.dispose();
    incomingStorage.dispose();
    incomingColor.dispose();
    incomingBuyPrice.dispose();
    incomingSellPrice.dispose();
    inventorySearch.dispose();
    super.dispose();
  }

Future<void> _loadInventoryFromApi() async {
    setState(() => loading = true);
    try {
      final response = await ApiService().getBuyPhones();
      if (response.containsKey('data')) {
        setState(() {
          inventoryPhones = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching inventory: $e")),
      );
    }
    setState(() => loading = false);
  }

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

  Future<void> _pickIncomingImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => incomingImageBytes = result.files.single.bytes!);
    }
  }
  // ==========================================================
  // IMAGE PICKER (LOCAL)
  // ==========================================================
  /// Picks incoming phone image as bytes
  /// Works on Flutter Web because we use `result.files.single.bytes`
  ///
  /// API integration later:
  /// - This image can be uploaded as MultipartFile (POST /products)


  // ==========================================================
  // INVENTORY SEARCH FILTER (LOCAL)
  // ==========================================================
  /// Filters inventoryPhones locally based on the search query.
  ///
  /// API integration later:
  /// - Replace this by GET /products/search?q=...
 Future<void> _confirmExchange() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a phone from inventory first")),
      );
      return;
    }


    final Map<String, dynamic> exchangeData = {
      "customer_name": personName.text.trim(),
      "customer_phone": personPhone.text.trim(),
      "received": {
        "model": incomingModel.text.trim(),
        "brand_id": selectedBrandId,
        "imei": incomingImei.text.trim(),
        "storage": incomingStorage.text.trim(),
        "color": incomingColor.text.trim(),
        "condition": "good", 
        "buy_price": double.tryParse(incomingBuyPrice.text.trim()) ?? 0,
        "resell_price": double.tryParse(incomingSellPrice.text.trim()) ?? 0,
      },
      "sold": {
         "buy_phone_id": selectedPhone!['id'],
         "price": selectedPhone!['resell_price'] ?? 0,
      }
    };

    setState(() => loading = true);
    try {
      final res = await ApiService().createExchange(exchangeData);
      if (res['success'] == true) {
        // Construct invoice data from local state to ensure PDF works
        final invoiceData = {
          "customer_name": personName.text,
          "customer_phone": personPhone.text,
          "customer_address": personAddress.text,
          "created_at": DateTime.now().toString().split('.')[0],
          "incoming_phone": {
            "model": incomingModel.text,
            "brand": incomingBrand.text,
            "color": incomingColor.text,
            "storage": incomingStorage.text,
            "imei": incomingImei.text,
            "selling_price": double.tryParse(incomingSellPrice.text) ?? 0,
          },
          "outgoing_phone": {
            ...selectedPhone!,
            "brand": selectedPhone!['brand'] is Map ? selectedPhone!['brand']['name'] : selectedPhone!['brand'],
            "selling_price": selectedPhone!['resell_price'] ?? 0,
          }
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExchangeInvoicePage(exchange: invoiceData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Exchange failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving exchange: $e")),
      );
    }
    setState(() => loading = false);
  }

  // ==========================================================
  // ADD INCOMING PHONE TO INVENTORY (LOCAL)
  // ==========================================================
  /// Adds the incoming phone into inventoryPhones list locally.
  ///
  /// Important:
  /// - Image is optional
  /// - Form validation must pass|
  ///
  /// API integration later:
  /// - Replace this by POST /products (incoming phone)
  void _addIncomingPhoneToInventory() {
    if (!formKey.currentState!.validate()) return;
    final auth = AuthService();

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
      "created_by": auth.user!['id'],

      // Local image bytes stored directly in memory
      "imageBytes": incomingImageBytes,
    };

    setState(() async {
      final response = await ApiService().addBuyPhone(productdata: incomingPhone);

      if (response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone added successfully!")),
        );
      } else {
        throw Exception(response['message'] ?? "Failed to add phone");
      }
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
 

  @override
  Widget build(BuildContext context) {
    final list = filteredInventory;
    final incomingPreviewImage = incomingImageBytes != null
        ? MemoryImage(incomingImageBytes!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Phone Exchange")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==========================================================
                // Customer + Incoming Phone Form
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
                        const Text("Customer Information",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _field(personName, "Name",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              if (v.trim().length < 3) return "Name too short";
                              return null;
                            }),
                        _field(personPhone, "Phone",
                            isNumber: true,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              if (v.trim().length < 8) return "Phone too short";
                              return null;
                            }),
                        _field(personAddress, "Address",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              return null;
                            }),
                        const Divider(height: 28),
                        const Text("Incoming Phone (Customer Phone)",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
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
                                  ))
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _field(incomingModel, "Model",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              if (v.trim().length < 2) return "Model too short";
                              return null;
                            }),
 FutureBuilder<List<Map<String, dynamic>>>(
  future: brands, 
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text("No brands available");
    } else {
      
      return DropdownButtonFormField<int>(
        decoration: _decoration("Brand"),
        items: snapshot.data!
            .map((b) => DropdownMenuItem(
                value: b['id'] as int, 
                child: Text(b['name'].toString())))
            .toList(),
        onChanged: (v) {
             setState(() {
                selectedBrandId = v;
                // Update text controller just in case, though not used now
                incomingBrand.text = snapshot.data!
                    .firstWhere((element) => element['id'] == v)['name'];
             });
        },
        validator: (v) => v == null ? "Required" : null,
      );
    }
  },
),
                        const SizedBox(height: 12),
                        _field(incomingColor, "Color",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              return null;
                            }),
                        _field(incomingImei, "IMEI (15 digits)",
                            isNumber: true,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              if (v.trim().length != 15) return "IMEI must be 15 digits";
                              return null;
                            }),
                        _field(incomingStorage, "Storage",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Required";
                              return null;
                            }),
                        _field(incomingBuyPrice, "Buy Price", isNumber: true,
                            validator: (v) {
                              final n = double.tryParse(v ?? "");
                              if (n == null) return "Must be a number";
                              if (n <= 0) return "Must be > 0";
                              return null;
                            }),
                        _field(incomingSellPrice, "Sell Price", isNumber: true,
                            validator: (v) {
                              final sell = double.tryParse(v ?? "");
                              final buy = double.tryParse(incomingBuyPrice.text) ?? 0;
                              if (sell == null) return "Must be a number";
                              if (sell <= 0) return "Must be > 0";
                              if (buy > 0 && sell < buy) return "Sell price can't be < Buy price";
                              return null;
                            }),
                      ],
                    ),
                  ),
                ),

                 const SizedBox(height: 20),
FutureBuilder<List<Map<String, dynamic>>>(
  future: availablePhonesFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    } else if (!snapshot.hasData || snapshot.data == null) {
      return const Text("No phones available to give");
    } else {
      final phones = snapshot.data!;
      
      return DropdownButtonFormField<Map<String, dynamic>>(
        decoration: _decoration("Phone to Give Customer"),
        items: phones.map((phone) {
          final brandName = phone['brand'] != null && phone['brand'] is Map 
              ? phone['brand']['name'] 
              : (phone['brand'] ?? '');
          final label = "$brandName ${phone['model']} (${phone['storage'] ?? ''}) - ${phone['resell_price'] ?? '?'}";
          return DropdownMenuItem<Map<String, dynamic>>(
            value: phone,
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (phone) {
          setState(() {
            selectedPhone = phone;
          });
        },
        validator: (v) => v == null ? "Required" : null,
      );
    }
  },
),
                const SizedBox(height: 20),

ElevatedButton(
  onPressed: () {
    if (formKey.currentState?.validate() ?? false) {
      // Here you can handle your submission logic
     _confirmExchange();
      // e.g., call API to save the exchange
    }
  },
  child: const Text("Submit"),
),

              ],
            ),
    );
  }

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
        validator: validator ?? (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF0E1A25),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
