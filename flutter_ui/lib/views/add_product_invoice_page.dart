import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AddProductInvoicePage extends StatelessWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? personInfo;

  /// product map expected keys:
  /// - model
  /// - imei
  /// - storage
  /// - color
  /// - purchase_price
  /// - quantity
  /// - source (supplier/person)
  ///
  /// personInfo map (optional, only for person source):
  /// - name
  /// - phone
  /// - address
  const AddProductInvoicePage({
    super.key,
    required this.product,
    this.personInfo,
  });

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final String source = (product["source"] ?? "").toString(); // supplier/person
    final bool isSupplier = source.toLowerCase() == "supplier";

    final String partyTitle =
        isSupplier ? "Supplier Information" : "Seller Information";

    final String invoiceTitle = isSupplier
        ? "Supplier Purchase Invoice / Facture"
        : "Personal Purchase Invoice / Facture";

    final String partyName = (personInfo?["name"] ??
            (isSupplier ? "Supplier Company" : "Customer"))
        .toString();

    final String partyPhone = (personInfo?["phone"] ?? "").toString();
    final String partyAddress = (personInfo?["address"] ?? "").toString();

    final String model = (product["model"] ?? "").toString();
    final String imei = (product["imei"] ?? "").toString();
    final String storage = (product["storage"] ?? "").toString();
    final String color = (product["color"] ?? "").toString();

    final int quantity =
        int.tryParse((product["quantity"] ?? 1).toString()) ?? 1;

    final double unitPrice =
        double.tryParse((product["purchase_price"] ?? 0).toString()) ?? 0;

    final double total = unitPrice * quantity;

    final String createdAt = DateTime.now().toIso8601String();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // HEADER (same style as exchange invoice)
              // ==========================================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Phone Store",
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoiceTitle,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1.2),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      "Stock Added",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 18),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // ==========================================================
              // PARTY INFO (supplier or seller)
              // ==========================================================
              pw.Text(
                partyTitle,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Name", partyName),
                    if (partyPhone.isNotEmpty) _infoRow("Phone", partyPhone),
                    if (partyAddress.isNotEmpty)
                      _infoRow("Address", partyAddress),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // ==========================================================
              // PRODUCT DETAILS
              // ==========================================================
              pw.Text(
                "Product Details",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow("Model", model),
                    if (color.isNotEmpty) _infoRow("Color", color),
                    if (storage.isNotEmpty) _infoRow("Storage", storage),
                    if (imei.isNotEmpty) _infoRow("IMEI", imei),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // ==========================================================
              // PURCHASE SUMMARY (quantity + unit + total)
              // ==========================================================
              pw.Text(
                "Purchase Summary",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    _priceRowText("Quantity", quantity.toString()),
                    _priceRowText(
                      "Price per Unit",
                      "\$${unitPrice.toStringAsFixed(2)}",
                    ),
                    pw.Divider(thickness: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ==========================================================
              // FOOTER
              // ==========================================================
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              pw.Text(
                "Date: $createdAt",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Stock successfully added to inventory.",
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Same info rows style but improved width (like exchange)
  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _priceRowText(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Invoice"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ✅ Back to previous page (Inventory/AddProduct)
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            tooltip: "Print",
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) => _buildPdf(format),
              );
            },
          ),
          IconButton(
            tooltip: "Download",
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              final pdfBytes = await _buildPdf(PdfPageFormat.a4);

              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    "purchase_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _buildPdf(format),
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
