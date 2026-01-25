// lib/screens/auth/login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ui/core/providers/login_provider.dart';
import 'package:flutter_ui/core/services/auth_service.dart';
import 'package:flutter_ui/views/DashBoard.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => LoginPage();
}

class LoginPage extends State<Login> {
  /// Global key used to access and validate the Form widget
  final formKey = GlobalKey<FormState>();

  /// Controls password visibility:
  /// true  => hidden
  /// false => visible
  bool obs = true;

  /// Controllers to read input data from text fields
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  /// Toggle password visibility (eye icon button)
  void togglePassword() {
    setState(() {
      obs = !obs;
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  /// Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final authService = AuthService();
    await authService.init();
    
    if (authService.isLoggedIn) {
      // Auto-navigate to dashboard if already logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    }
  }

  @override
  void dispose() {
    /// Dispose controllers when leaving page
    /// Prevents memory leaks in Flutter
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Consumer<LoginProvider>(
        builder: (context, loginProvider, child) {
          return _buildLoginScreen(context, loginProvider);
        },
      ),
    );
  }

  Widget _buildLoginScreen(BuildContext context, LoginProvider loginProvider) {
    /// LayoutBuilder lets us build responsive UI based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        /// If width > 800, we consider it Desktop
        final bool isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Center(
            child: SingleChildScrollView(
              child: SizedBox(
                /// Desktop -> fixed width
                /// Mobile -> full width
                width: isDesktop ? 450 : double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      _buildLogo(),
                      const SizedBox(height: 32),

                      // Login Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildLoginForm(loginProvider),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Demo Credentials Card
                      if (!loginProvider.isLoading) _buildDemoCredentials(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.phone_android,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Phone Store Manager',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Professional Store Management System',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(LoginProvider loginProvider) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Error Message
          if (loginProvider.errorMessage != null)
            _buildErrorAlert(loginProvider.errorMessage!),

          const SizedBox(height: 16),

          // Username Input
          TextFormField(
            controller: username,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: "Enter your username",
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Input
          TextFormField(
            controller: password,
            obscureText: obs,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  obs ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: togglePassword,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: loginProvider.isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        
                        try {
                          await loginProvider.login(
                            username: username.text,
                            password: password.text,
                          );
                          
                          if (loginProvider.isSuccess) {
                            // Navigate to dashboard on success
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashboardPage(),
                              ),
                            );
                          }
                        } catch (e) {
                          // Error is already handled by provider
                        }
                      }
                    },
              child: loginProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Forgot Password / Setup Link
          _buildExtraLinks(context),
        ],
      ),
    );
  }

  Widget _buildErrorAlert(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraLinks(BuildContext context) {
    return Column(
      children: [
        // First Time Setup
        TextButton(
          onPressed: () {
            // Navigate to setup screen
            // Navigator.pushNamed(context, '/setup');
          },
          child: const Text(
            'First Time Setup? Create Super Admin',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'or',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Register Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () {
                // Note: Registration is super-admin only
                // So we show a message instead
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'User registration is admin-only. Contact your administrator.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text("Contact Admin"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoCredentials() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo Credentials:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildCredentialItem('Super Admin', 'superadmin', 'admin123'),
            const SizedBox(height: 4),
            _buildCredentialItem('Store Manager', 'manager', 'manager123'),
            const SizedBox(height: 4),
            _buildCredentialItem('Sales Person', 'seller', 'seller123'),
            const SizedBox(height: 4),
            _buildCredentialItem('Technician', 'technician', 'tech123'),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialItem(String role, String username, String password) {
    return Row(
      children: [
        Text(
          '$role: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            this.username.text = username;
            this.password.text = password;
            // Auto-fill the form
            formKey.currentState?.validate();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '$username / $password',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}