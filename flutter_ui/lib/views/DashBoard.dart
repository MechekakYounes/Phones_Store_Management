import 'package:flutter/material.dart';

/// DashboardPage:
/// - Shows business overview
/// - Has navigation to inventory
/// - Adds Exchange button in AppBar actions (beside notification)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// Selected index for navigation (Mobile bottom nav / Desktop rail)
  int selectedIndex = 0;
  final List<Map<String, dynamic>> localHistory = [];
  void addHistory(Map<String, dynamic> item) {
    localHistory.insert(0, item); // newest first
  }

  /// Navigate based on selected index
  void _navigate(int index) {
    setState(() => selectedIndex = index);

    if (index == 1) {
      Navigator.pushNamed(context, '/inventory');
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/history');
    }
    if (index == 3) {
      // logout for later
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.phone_android),
            SizedBox(width: 10),
            Text("Phone Store"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "Phone Exchange",
            onPressed: () {
              Navigator.pushNamed(context, '/exchange');
            },
          ),
        ],
      ),

      /// Mobile bottom navigation
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: _navigate,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Logout',
                ),
              ],
            ),

      body: Row(
        children: [
          /// Desktop navigation rail
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _navigate,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory),
                  label: Text('Inventory'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                ),
              ],
            ),

          /// Dashboard content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 20),
                _statsRow(),
                const SizedBox(height: 24),
                _salesOverview(),
                const SizedBox(height: 24),
                _recentTransactions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== UI SECTIONS =====================

  /// Header section (Welcome + Avatar)
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text(
              'Hello, Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        CircleAvatar(child: Icon(Icons.person)),
      ],
    );
  }

  /// Small stat cards section
  Widget _statsRow() {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: "Today's Sales",
            value: "\$1,240.00",
            icon: Icons.attach_money,
            badge: "+12%",
            badgeColor: Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: "Total Profit",
            value: "+\$450.00",
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  /// Sales Overview section (with chart placeholder)
  Widget _salesOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Sales Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            '\$8,420',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text('↑ 12.5% from last week', style: TextStyle(color: Colors.green)),
          SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Chart Placeholder',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Recent Transactions list
  Widget _recentTransactions() {
    final recent = localHistory.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/history");
              },
              child: const Text("See all"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          const Text(
            "No transactions yet.",
            style: TextStyle(color: Colors.grey),
          )
        else
          ...recent.map((h) {
            return _TransactionTile(
              (h["title"] ?? "Unknown").toString(),
              h["amount"] != null ? "\$${h["amount"]}" : "",
              (h["created_at"] is DateTime)
                  ? (h["created_at"] as DateTime).toIso8601String()
                  : "",
            );
          }).toList(),
      ],
    );
  }
}

// ===================== COMPONENTS =====================

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name, price, time;

  const _TransactionTile(this.name, this.price, this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
