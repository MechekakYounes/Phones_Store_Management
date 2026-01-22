import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String filter = "all"; // all | add | sale | exchange
  final List<Map<String, dynamic>> localHistory = [];

  void addHistory(Map<String, dynamic> item) {
    localHistory.insert(0, item); // newest first
  }

  List<Map<String, dynamic>> get filteredHistory {
    if (filter == "all") return localHistory;
    return localHistory.where((h) => h["type"] == filter).toList();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "add":
        return Icons.add_box;
      case "sale":
        return Icons.shopping_cart;
      case "exchange":
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case "add":
        return Colors.blue;
      case "sale":
        return Colors.green;
      case "exchange":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hour(s) ago";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredHistory;

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: Column(
        children: [
          // FILTER BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1C2B3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("All")),
                      DropdownMenuItem(value: "add", child: Text("Added")),
                      DropdownMenuItem(value: "sale", child: Text("Sales")),
                      DropdownMenuItem(
                        value: "exchange",
                        child: Text("Exchanges"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => filter = v ?? "all");
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: "Clear history",
                  onPressed: () {
                    setState(() {
                      localHistory.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),

          // HISTORY LIST
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      "No history yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final h = list[i];
                      final type = (h["type"] ?? "").toString();
                      final title = (h["title"] ?? "Unknown").toString();
                      final subtitle = (h["subtitle"] ?? "").toString();
                      final amount = h["amount"];
                      final createdAt = h["created_at"] as DateTime?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2B3A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _colorForType(type),
                              child: Icon(
                                _iconForType(type),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    createdAt != null
                                        ? _formatTime(createdAt)
                                        : "",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (amount != null)
                              Text(
                                "\$${amount.toString()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
