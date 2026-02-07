import 'package:flutter/material.dart';
import 'package:flutter_ui/diags/logout_diag.dart';
import 'package:flutter_ui/core/services/auth_service.dart';
import 'package:flutter_ui/core/services/dashboard_service.dart';
import 'package:flutter_ui/views/Login.dart';

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
  
  /// Dashboard data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load dashboard data from API
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dashboardService.getStatistics();
      if (response['success'] == true) {
        setState(() {
          _dashboardData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard: $e';
        _isLoading = false;
      });
    }
  }

  /// Navigate based on selected index
  void _navigate(int index) async {
    setState(() => selectedIndex = index);

    if (index == 1) {
      Navigator.pushNamed(context, '/inventory');
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/history');
    }
    if (index == 3) {
      // Logout tab
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => const LogoutDialog(),
      );

      if (confirm == true) {
        final success = await AuthService().logout();

        if (success && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Login()),
            (route) => false,
          );
        }
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 80, height: 80, scale: 0.25),
            SizedBox(width: 10),
            Text("Rabah Phone Store"),
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
                  icon: Icon(Icons.dashboard, color: Colors.white),
                  label: 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory, color: Colors.white),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history, color: Colors.white),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout, color: Colors.white),
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
                  icon: Icon(Icons.dashboard, color: Colors.white),
                  label: Text(
                    'Overview',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory, color: Colors.white),
                  label: Text(
                    'Inventory',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history, color: Colors.white),
                  label: Text('History', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

          /// Dashboard content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDashboardData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
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
    final todaySales = _dashboardData?['today_sales'] ?? {};
    final totalProfit = _dashboardData?['total_profit'] ?? {};
    
    final salesAmount = todaySales['amount'] ?? 0.0;
    final salesChange = todaySales['change_percent'] ?? 0.0;
    final profitAmount = totalProfit['amount'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Today's Sales",
            value: "\$${salesAmount.toStringAsFixed(2)}",
            icon: Icons.attach_money,
            badge: "${salesChange >= 0 ? '+' : ''}${salesChange.toStringAsFixed(1)}%",
            badgeColor: salesChange >= 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: "Total Profit",
            value: "${profitAmount >= 0 ? '+' : ''}\$${profitAmount.toStringAsFixed(2)}",
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  /// Sales Overview section (with chart placeholder)
  Widget _salesOverview() {
    final weeklySales = _dashboardData?['weekly_sales'] ?? {};
    final weeklyAmount = weeklySales['amount'] ?? 0.0;
    final weeklyChange = weeklySales['change_percent'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${weeklyAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${weeklyChange >= 0 ? '↑' : '↓'} ${weeklyChange.abs().toStringAsFixed(1)}% from last week',
            style: TextStyle(color: weeklyChange >= 0 ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 16),
          const SizedBox(
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
    final recentTransactions = _dashboardData?['recent_transactions'] as List<dynamic>? ?? [];

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
        if (recentTransactions.isEmpty)
          const Text(
            "No transactions yet.",
            style: TextStyle(color: Colors.grey),
          )
        else
          ...recentTransactions.map((transaction) {
            final title = transaction['title'] ?? 'Unknown';
            final amount = transaction['amount'] ?? 0.0;
            final createdAt = transaction['created_at'] ?? '';
            
            return _TransactionTile(
              title,
              "\$${amount.toStringAsFixed(2)}",
              createdAt,
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
