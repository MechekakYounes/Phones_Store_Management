import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ui/core/providers/login_provider.dart';
import 'package:flutter_ui/core/services/auth_service.dart';
import 'package:flutter_ui/views/DashBoard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginPage();
}

class LoginPage extends State<Login> {
  final formKey = GlobalKey<FormState>();

  bool obs = true;

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  void togglePassword() {
    setState(() {
      obs = !obs;
    });
  }

  @override
  void initState() {
    super.initState();

    // Keep API integration: auto-check login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final authService = AuthService();
    await authService.init();

    if (authService.isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  @override
  void dispose() {
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth > 800;

              return Scaffold(
                body: Center(
                  child: SizedBox(
                    width: isDesktop ? 450 : double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App icon (old UI)
                            const Icon(
                              Icons.store,
                              size: 64,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),

                            // Title
                            const Text(
                              'Shop Manager',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            const Text(
                              'Log in to manage your inventory',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 32),

                            // API Error message (kept from provider)
                            if (loginProvider.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  loginProvider.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Username input (old UI style)
                            TextFormField(
                              controller: username,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: "Enter your username",
                                filled: true,
                                fillColor: const Color(0xFF1C2B3A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "please fill your informations"
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Password input (old UI style)
                            TextFormField(
                              controller: password,
                              obscureText: obs,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                filled: true,
                                fillColor: const Color(0xFF1C2B3A),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obs
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: togglePassword,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "please fill your informations"
                                  : null,
                            ),

                            const SizedBox(height: 24),

                            // Login button (old UI style, new logic)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: loginProvider.isLoading
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate())
                                          return;

                                        try {
                                          await loginProvider.login(
                                            username: username.text.trim(),
                                            password: password.text.trim(),
                                          );

                                          if (loginProvider.isSuccess &&
                                              mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const DashboardPage(),
                                              ),
                                            );
                                          }
                                        } catch (e) { 
                                          String message =
                                              "Something went wrong. Please try again.";

                                          if (e.toString().contains("401")) {
                                            message =
                                                "Wrong username or password";
                                          } else if (e.toString().contains(
                                            "SocketException",
                                          )) {
                                            message = "No internet connection";
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(message)), // --> this is ued for debug in case of failed login the error shows up 
                                          );
                                        }
                                      },
                                child: loginProvider.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Old UI register link (keep it)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(color: Colors.blue),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/register',
                                    );
                                  },
                                  child: const Text("Sign Up"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
