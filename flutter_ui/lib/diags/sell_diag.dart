import 'package:flutter/material.dart';

class SellDialog extends StatelessWidget {
  final Map<String, dynamic> product;

  const SellDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirm Sale"),
      content: Text(
        "Do you want to sell this phone?\n\n"
        "Model: ${product['model']}\n"
        "IMEI: ${product['imei']}\n"
        "Price: \$${product['resell_price'] ?? product['selling_price']}",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // close dialog

            // Go to SalePage (full sale workflow)
            Navigator.pushNamed(
              context,
              '/sale',
              arguments: product['id'], // only pass the ID
            );
          },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
