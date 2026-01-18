import 'package:flutter/material.dart';

/// --------------------------------------------
/// Login Page
/// --------------------------------------------
/// This page allows the user to log into the app.
/// have :
/// Form validation
/// Responsive layout (Desktop / Mobile)
/// Password hide/show toggle
/// Navigation:
///    - Success login -> /dashboard
///    - No account -> /register
class Login extends StatefulWidget {
  @override
  State<Login> createState() => LoginPage();
}

class LoginPage extends State<Login> {
  /// Global key used to access and validate the Form widget
  final formKey = GlobalKey<FormState>();

  /// Temporary flag for login result
  /// Later: replace by API login response
  bool success = true;

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
  void dispose() {
    /// Dispose controllers when leaving page
    /// Prevents memory leaks in Flutter
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// LayoutBuilder lets us build responsive UI based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        /// If width > 800, we consider it Desktop
        final bool isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          body: Center(
            child: SizedBox(
              /// Desktop -> fixed width
              /// Mobile -> full width
              width: isDesktop ? 450 : double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),

                /// Form widget wraps all inputs so we can validate them together
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// App icon
                      const Icon(Icons.store, size: 64, color: Colors.blue),
                      const SizedBox(height: 16),

                      /// App title
                      const Text(
                        'Shop Manager',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// Subtitle
                      const Text(
                        'Log in to manage your inventory',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // --------------------------
                      // Username Input
                      // --------------------------
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

                        /// Simple validation rule
                        validator: (v) =>
                            v!.isEmpty ? "please fill your informations" : null,
                      ),

                      const SizedBox(height: 16),

                      // --------------------------
                      // Password Input
                      // --------------------------
                      TextFormField(
                        controller: password,

                        /// Hide password based on obs
                        obscureText: obs,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: const Color(0xFF1C2B3A),

                          /// Eye icon to toggle password visibility
                          suffixIcon: IconButton(
                            icon: Icon(
                              obs ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: togglePassword,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        /// Validation rule
                        validator: (v) =>
                            v!.isEmpty ? "please fill your informations" : null,
                      ),

                      const SizedBox(height: 24),

                      // --------------------------
                      // Sign In Button
                      // --------------------------
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
                          onPressed: () {
                            /// Validate form fields
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();

                              /// Later:
                              /// - call API to verify login
                              /// - update success depending on response
                            }

                            /// Temporary success check
                            if (success) {
                              /// Replace current page with dashboard
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            }
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --------------------------
                      // Navigate to Register Page
                      // --------------------------
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
  }
}
