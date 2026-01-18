import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/*
  AddSource:
  Defines where the product came from.

  supplier:
    Product is added from a supplier.
    Quantity is important (can be more than 1).

  person:
    Product is added from a customer/person.
    Quantity is always 1 (single device).
*/
enum AddSource { supplier, person }

/*
  ProductCategory:
  Defines the product type.
  This is used to decide which fields are required and shown in the form.

  phone:
    Has IMEI, storage, and color fields.

  accessory:
    No IMEI or storage required.

  electromenage:
    Treated as non-phone items.
*/
enum ProductCategory { phone, accessory, electromenage }

/*
  InventoryPage (Local version):
  This page displays the inventory list (products), supports searching,
  and allows adding new products using AddProductPage.

  Current Version:
    Local only (in-memory list).
    Data is lost if you restart the app.

  API Integration Later:
    - Load products using GET /products
    - Search products using GET /products/search?q=
    - Add product using POST /products
*/
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  /*
    This local list holds all products in memory.

    Each product is a Map<String, dynamic> with keys such as:
      - brand_id
      - category_id
      - model
      - storage
      - color
      - imei
      - purchase_price
      - selling_price
      - quantity
      - imageBytes (Uint8List?)
      - source
  */
  final List<Map<String, dynamic>> inventory = [];

  // Search input controller and current query
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    searchController.dispose();
    super.dispose();
  }

  /*
    filteredInventory:
    Returns the list of products that match the search query.

    Search matches:
      - model
      - imei
      - storage
      - color

    API Integration Later:
      Replace this local filtering with an API call:
      GET /products/search?q=<searchQuery>

      Then you setState(() => inventory = responseFromApi)
  */
  List<Map<String, dynamic>> get filteredInventory {
    if (searchQuery.trim().isEmpty) return inventory;

    final q = searchQuery.toLowerCase();
    return inventory.where((p) {
      final model = (p["model"] ?? "").toString().toLowerCase();
      final imei = (p["imei"] ?? "").toString().toLowerCase();
      final storage = (p["storage"] ?? "").toString().toLowerCase();
      final color = (p["color"] ?? "").toString().toLowerCase();

      return model.contains(q) ||
          imei.contains(q) ||
          storage.contains(q) ||
          color.contains(q);
    }).toList();
  }

  /*
    Opens the AddProductPage.

    Local behavior:
      AddProductPage returns the new product as a Map.
      We insert the product into inventory and refresh UI.

    API Integration Later:
      Instead of returning a Map, you can call POST /products
      and then reload inventory from the backend.
  */
  void _openAddProduct() async {
    final newProduct = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );

    if (newProduct != null) {
      setState(() {
        inventory.add(newProduct);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the list being shown (filtered or full inventory)
    final list = filteredInventory;

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProduct,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar to filter products locally
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search by model / IMEI / storage / color...",
                filled: true,
                fillColor: const Color(0xFF1C2B3A),
                prefixIcon: const Icon(Icons.search),

                // Clear button appears only when text exists
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = "");
                        },
                      )
                    : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /*
            Main body:
            If list is empty, show a "No products found" message.
            Otherwise show the products using ListView.builder.
          */
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      "No products found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => InventoryCard(
                      product: list[i],

                      /*
                        Sell button navigation:

                        Sends the full product Map to SalePage
                        using Navigator arguments.

                        API Integration Later:
                          SalePage should call:
                          POST /sales
                          and update product quantity using:
                          PATCH /products/<id>
                      */
                      onSell: () {
                        Navigator.pushNamed(
                          context,
                          '/sale',
                          arguments: list[i],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/*
  InventoryCard:
  Displays product information in a clean row layout:
    - Image on the left
    - Text details in the middle
    - Selling price + Sell button on the right

  Image loading:
    Local mode uses Uint8List in product["imageBytes"].
    If no image is provided, a placeholder asset is shown.

  API Integration Later:
    Instead of "imageBytes", you might store "image_url"
    and display it using NetworkImage(imageUrl).
*/
class InventoryCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSell;

  const InventoryCard({
    super.key,
    required this.product,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    // Read image bytes stored locally (works on Flutter web + mobile)
    final Uint8List? imageBytes = product["imageBytes"];

    // If bytes exist -> MemoryImage, else -> placeholder
    final ImageProvider imageProvider = imageBytes != null
        ? MemoryImage(imageBytes)
        : const AssetImage("assets/placeholder.png");

    return Container(
      height: 125,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(width: 12),

          // Product details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["model"]?.toString() ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Optional fields only appear if not empty
                if ((product["color"] ?? "").toString().isNotEmpty)
                  Text(
                    "Color: ${product["color"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                if ((product["imei"] ?? "").toString().isNotEmpty)
                  Text(
                    "IMEI: ${product["imei"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                if ((product["storage"] ?? "").toString().isNotEmpty)
                  Text(
                    "Storage: ${product["storage"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Price + Sell Button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "\$${product["selling_price"] ?? "0"}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(onPressed: onSell, child: const Text("Sell")),
            ],
          ),
        ],
      ),
    );
  }
}

/*
  AddProductPage (Local version):
  Form used to create a new product and return it back to InventoryPage.

  Local behavior:
    - User fills the form
    - Selects optional image using FilePicker
    - Presses Add to Inventory
    - Returns a Map<String, dynamic> to InventoryPage

  API Integration Later:
    Replace Navigator.pop(context, product) with:
      ApiService.addProduct(...)
    and then refresh inventory list from backend.
*/
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final formKey = GlobalKey<FormState>();

  // User-selected source and category
  AddSource source = AddSource.supplier;
  ProductCategory category = ProductCategory.phone;

  // Main product controllers
  final TextEditingController model = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController imei = TextEditingController();
  final TextEditingController storage = TextEditingController();
  final TextEditingController color = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: "1");
  final TextEditingController buyPrice = TextEditingController();
  final TextEditingController sellPrice = TextEditingController();

  // Extra customer fields when source is person
  final TextEditingController personName = TextEditingController();
  final TextEditingController personPhone = TextEditingController();
  final TextEditingController personAddress = TextEditingController();

  // Local image storage
  Uint8List? pickedImageBytes;

  bool loading = false;

  // Local brand list (can later be loaded from API)
  final brandsList = [
    'Apple',
    'Samsung',
    'Xiaomi',
    'Huawei',
    'Oppo',
    'Realme',
    'Google',
    'Nokia',
    'LG',
    'Bosch',
  ];

  bool get isPhone => category == ProductCategory.phone;
  bool get isSupplier => source == AddSource.supplier;

  @override
  void dispose() {
    // Dispose all controllers
    model.dispose();
    brand.dispose();
    imei.dispose();
    storage.dispose();
    color.dispose();
    quantity.dispose();
    buyPrice.dispose();
    sellPrice.dispose();

    personName.dispose();
    personPhone.dispose();
    personAddress.dispose();

    super.dispose();
  }

  /*
    Picks an image using FilePicker.

    Local behavior:
      - Reads bytes directly (web compatible)
      - Stores them in pickedImageBytes

    API Integration Later:
      Send this image as multipart upload to backend:
        POST /products with form-data + file
  */
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        pickedImageBytes = result.files.single.bytes!;
      });
    }
  }

  /*
    Validates and creates a new product Map.

    Local behavior:
      Returns the product to InventoryPage using Navigator.pop.

    API Integration Later:
      Replace the returned Map with:
        ApiService.addProduct(...)
  */
  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final product = {
        "brand_id": brandsList.indexOf(brand.text) + 1,
        "category_id": category.index + 1,
        "model": model.text.trim(),
        "storage": isPhone ? storage.text.trim() : null,
        "color": isPhone ? color.text.trim() : null,
        "imei": isPhone ? imei.text.trim() : null,
        "purchase_price": double.parse(buyPrice.text.trim()),
        "selling_price": double.parse(sellPrice.text.trim()),
        "quantity": isSupplier ? int.parse(quantity.text.trim()) : 1,

        // Local image stored in memory
        "imageBytes": pickedImageBytes,

        // Useful for later database integration
        "source": source.name,
      };

      if (!mounted) return;
      Navigator.pop(context, product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Source"),
              const SizedBox(height: 8),

              // Select product source (supplier or user)
              ToggleButtons(
                isSelected: [
                  source == AddSource.supplier,
                  source == AddSource.person,
                ],
                onPressed: (i) {
                  setState(() {
                    source = i == 0 ? AddSource.supplier : AddSource.person;

                    // If source = person, accessory is not allowed
                    if (source == AddSource.person &&
                        category == ProductCategory.accessory) {
                      category = ProductCategory.phone;
                    }
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Supplier"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("User"),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text("Product Type"),
              const SizedBox(height: 8),

              // Select product category
              ToggleButtons(
                isSelected: source == AddSource.supplier
                    ? [
                        category == ProductCategory.phone,
                        category == ProductCategory.accessory,
                        category == ProductCategory.electromenage,
                      ]
                    : [
                        category == ProductCategory.phone,
                        category == ProductCategory.electromenage,
                      ],
                onPressed: (i) {
                  setState(() {
                    if (source == AddSource.supplier) {
                      category = ProductCategory.values[i];
                    } else {
                      category = i == 0
                          ? ProductCategory.phone
                          : ProductCategory.electromenage;
                    }
                  });
                },
                children: source == AddSource.supplier
                    ? const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Phone"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Accessory"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Electromenage"),
                        ),
                      ]
                    : const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Phone"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Electromenage"),
                        ),
                      ],
              ),

              const SizedBox(height: 20),

              // Image selection (optional)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Pick Image (optional)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                ],
              ),

              // Image preview
              if (pickedImageBytes != null) ...[
                const SizedBox(height: 10),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    image: DecorationImage(
                      image: MemoryImage(pickedImageBytes!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Product model input (required)
              _field(
                model,
                "Model",
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Model is required" : null,
              ),

              // Brand selection (required)
              DropdownButtonFormField(
                decoration: _decoration("Brand"),
                items: brandsList
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => brand.text = v!,
                validator: (v) => v == null ? "Brand is required" : null,
              ),

              const SizedBox(height: 20),

              // Phone fields only
              if (isPhone) ...[
                _field(
                  color,
                  "Color",
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Color is required"
                      : null,
                ),
                _field(
                  imei,
                  "IMEI (16 digits)",
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "IMEI required";
                    if (v.length != 16) return "IMEI must be 16 digits";
                    return null;
                  },
                ),
                _field(
                  storage,
                  "Storage",
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Storage required"
                      : null,
                ),
              ],

              // Supplier: quantity is required for phones
              if (isSupplier && isPhone)
                _field(
                  quantity,
                  "Quantity",
                  isNumber: true,
                  validator: (v) {
                    final n = int.tryParse(v ?? "");
                    if (n == null) return "Quantity must be a number";
                    if (n <= 0) return "Quantity must be > 0";
                    return null;
                  },
                ),

              // Person section (only shown if source == person)
              if (!isSupplier) ...[
                const Divider(),
                const Text("User Information"),
                _field(personName, "Name"),
                _field(personPhone, "Phone"),
                _field(personAddress, "Address"),
                const Divider(),
              ],

              // Buy/Sell prices
              _field(
                buyPrice,
                "Buy Price",
                isNumber: true,
                validator: (v) {
                  final n = double.tryParse(v ?? "");
                  if (n == null) return "Buy price must be a number";
                  if (n <= 0) return "Buy price must be > 0";
                  return null;
                },
              ),
              _field(
                sellPrice,
                "Sell Price",
                isNumber: true,
                validator: (v) {
                  final n = double.tryParse(v ?? "");
                  if (n == null) return "Sell price must be a number";
                  if (n <= 0) return "Sell price must be > 0";
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Add to Inventory"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
    _field:
    Reusable TextFormField builder with consistent styling.
  */
  Widget _field(
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
        decoration: _decoration(label),
        validator: validator ?? (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  /*
    _decoration:
    Centralized input decoration to keep the UI consistent.
  */
  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF1C2B3A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
