import 'package:flutter/material.dart';
import '../core/services/api_service.dart';

class SellDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSold;

  const SellDialog({
    super.key,
    required this.product,
    required this.onSold,
  });

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  final TextEditingController _priceController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final soldPrice = double.tryParse(_priceController.text);
    if (soldPrice == null) return;

    setState(() => _loading = true);

    try {
      await ApiService().sellPhone(
        id: widget.product['id'],
        soldPrice: soldPrice,
      );

      widget.onSold();        // refresh inventory
      Navigator.pop(context); // close dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sell failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sell Phone"),
      content: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Sold Price",
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Confirm"),
        ),
      ],
    );
  }
}
