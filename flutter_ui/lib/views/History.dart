import 'package:flutter/material.dart';
import 'package:flutter_ui/core/services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String filter = "all"; // all | add | sale | exchange
  bool isLoading = true;
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService().getHistory();

      if (response['success'] == true) {
        final List data = response['data'];
        setState(() {
          history = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load history");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("History error: $e")),
      );
    }
  }

  List<Map<String, dynamic>> get filteredHistory {
    if (filter == "all") return history;
    return history.where((h) => h["type"] == filter).toList();
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

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";

    final diff = DateTime.now().difference(dt);

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
                  tooltip: "Refresh",
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(
                        child: Text(
                          "No history found.",
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
                          final subtitle =
                              (h["subtitle"] ?? "").toString();
                          final amount = h["amount"];
                          final createdAt =
                              (h["created_at"] ?? "").toString();

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        _formatTime(createdAt),
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
