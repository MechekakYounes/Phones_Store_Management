import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> sale;

  const InvoicePage({super.key, required this.sale});

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final String buyerName = (sale["buyer_name"] ?? "").toString();
    final String buyerPhone = (sale["buyer_phone"] ?? "").toString();
    final String buyerAddress = (sale["buyer_address"] ?? "").toString();

    final String model = (sale["model"] ?? "").toString();
    final String imei = (sale["imei"] ?? "").toString();
    final String storage = (sale["storage"] ?? "").toString();
    final String color = (sale["color"] ?? "").toString();

    final double price = double.parse((sale["price"] ?? 0));
    final double discount = double.parse((sale["discount"] ?? 0));
    final String total = (sale["total"] ?? (price - discount)).toString();


    final String createdAt = (sale["created_at"] ?? "").toString();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
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
                        "Invoice / Facture",
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
                      "Paid",
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

              // BUYER INFO
              pw.Text(
                "Buyer Information",
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
                    _infoRow("Name", buyerName),
                    _infoRow("Phone", buyerPhone),
                    _infoRow("Address", buyerAddress),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // PRODUCT INFO
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

              // TOTALS
              pw.Text(
                "Payment Summary",
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
                    _priceRow("Price", price.toDouble()),
                    _priceRow("Discount", discount.toDouble()),
                    pw.Divider(thickness: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.Text(
                          "\$${total.toString()}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // FOOTER
              pw.Text(
                "Date: $createdAt",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Thank you for your purchase.",
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
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

  static pw.Widget _priceRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text("\$${value.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          },
        ),

        // Action buttons (Print + Download)
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
            icon: const Icon(Icons.download),
            onPressed: () async {
              final pdfBytes = await _buildPdf(PdfPageFormat.a4);

              await Printing.sharePdf(
                bytes: pdfBytes,
                filename:
                    "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
              );
            },
          ),
        ],
      ),

      // PdfPreview with NO SWITCHES
      body: PdfPreview(
        build: (format) => _buildPdf(format),

        // We keep print + download manually from AppBar
        allowPrinting: false,
        allowSharing: false,

        // Remove the format switch and any settings
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,

        // Optional filename if the widget ever uses it
        pdfFileName: "invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
      ),
    );
  }
}
