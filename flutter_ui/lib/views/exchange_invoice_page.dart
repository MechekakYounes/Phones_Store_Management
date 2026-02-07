import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExchangeInvoicePage extends StatelessWidget {
  final Map<String, dynamic> exchange;

  const ExchangeInvoicePage({super.key, required this.exchange});

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final String customerName = (exchange["customer_name"] ?? "").toString();
    final String customerPhone = (exchange["customer_phone"] ?? "").toString();
    final String customerAddress =
        (exchange["customer_address"] ?? "").toString();

    final Map<String, dynamic> incomingPhone =
        (exchange["incoming_phone"] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> outgoingPhone =
        (exchange["outgoing_phone"] ?? {}) as Map<String, dynamic>;

    final String createdAt = (exchange["created_at"] ?? "").toString();
    double _parseDouble(dynamic value) {
         if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}


    final double outgoingPrice = _parseDouble(outgoingPhone["selling_price"]);
    final double incomingPrice = _parseDouble(incomingPhone["selling_price"]);
    final double difference = outgoingPrice - incomingPrice;
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
                        "Exchange Invoice / Facture",
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
                      "Exchange",
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

              // CUSTOMER INFO
              pw.Text(
                "Customer Information",
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
                    _infoRow("Name", customerName),
                    _infoRow("Phone", customerPhone),
                    _infoRow("Address", customerAddress),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // INCOMING PHONE
              pw.Text(
                "Incoming Phone (Customer Phone)",
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
                    _infoRow("Model", (incomingPhone["model"] ?? "").toString()),
                    _infoRow("Brand", (incomingPhone["brand"] ?? "").toString()),
                    if ((incomingPhone["color"] ?? "").toString().isNotEmpty)
                      _infoRow(
                          "Color", (incomingPhone["color"] ?? "").toString()),
                    if ((incomingPhone["storage"] ?? "").toString().isNotEmpty)
                      _infoRow("Storage",
                          (incomingPhone["storage"] ?? "").toString()),
                    if ((incomingPhone["imei"] ?? "").toString().isNotEmpty)
                      _infoRow("IMEI", (incomingPhone["imei"] ?? "").toString()),
                    _infoRow(
                      "Estimated Value",
                      "\$${incomingPrice.toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // OUTGOING PHONE
              pw.Text(
                "Outgoing Phone (Shop Phone)",
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
                    _infoRow("Model", (outgoingPhone["model"] ?? "").toString()),
                    _infoRow("Brand", (outgoingPhone["brand"] ?? "").toString()),
                    if ((outgoingPhone["color"] ?? "").toString().isNotEmpty)
                      _infoRow(
                          "Color", (outgoingPhone["color"] ?? "").toString()),
                    if ((outgoingPhone["storage"] ?? "").toString().isNotEmpty)
                      _infoRow("Storage",
                          (outgoingPhone["storage"] ?? "").toString()),
                    if ((outgoingPhone["imei"] ?? "").toString().isNotEmpty)
                      _infoRow("IMEI", (outgoingPhone["imei"] ?? "").toString()),
                    _infoRow(
                      "Selling Price",
                      "\$${outgoingPrice.toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // SUMMARY
              pw.Text(
                "Exchange Summary",
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
                    _priceRow("Outgoing Phone Price", outgoingPrice),
                    _priceRow("Incoming Phone Value", incomingPrice),
                    pw.Divider(thickness: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Customer Pays Difference",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          "\$${difference.toStringAsFixed(2)}",
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

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              pw.Text(
                "Date: $createdAt",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Thank you for your trust.",
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
        title: const Text("Exchange Invoice"),
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
                    "exchange_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
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
