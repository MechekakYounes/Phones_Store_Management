import 'package:flutter/material.dart';

/// --------------------------------------------
/// Register Page
/// --------------------------------------------
/// This page allows creating a new user account.
/// It supports:
/// Form validation
/// Responsive layout (Desktop / Mobile)
/// Password hide/show toggle for:
///    - Password
///    - Confirm Password
/// Navigation:
///    - Success register -> /dashboard
///    - Back to login -> /login
///
/// Later API Integration:
/// Validate username uniqueness
/// Validate Super Admin Password from backend
/// Create user account and store token/session
class Register extends StatefulWidget {
  @override
  State<Register> createState() => RegisterPage();
}

class RegisterPage extends State<Register> {
  /// Global key used to validate the form inputs
  final formKey = GlobalKey<FormState>();

  /// Temporary success flag
  /// Later: replace by API response (true/false)
  bool success = true;

  /// Password visibility:
  /// true  => hidden
  /// false => visible
  bool obsPassword = true;

  /// Confirm password visibility:
  /// true  => hidden
  /// false => visible
  bool obsConfirm = true;

  // --------------------------------------------
  // Controllers for form inputs
  // --------------------------------------------

  /// Username controller
  final TextEditingController username = TextEditingController();

  /// Password controller
  final TextEditingController password = TextEditingController();

  /// Confirm password controller
  final TextEditingController confirmPassword = TextEditingController();

  /// Super admin password controller (required to create new user)
  final TextEditingController superAdminPassword = TextEditingController();

  @override
  void dispose() {
    /// Dispose controllers to prevent memory leaks
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
    superAdminPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Detect desktop mode based on screen width
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Center(
        child: SizedBox(
          /// Desktop uses fixed width to look modern
          /// Mobile uses full width
          width: isDesktop ? 450 : double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),

            /// Form wraps all TextFormFields to validate them together
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --------------------------------------------
                  // Logo + Title
                  // --------------------------------------------
                  const Icon(Icons.store, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Shop Manager',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new user',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // --------------------------------------------
                  // Username field
                  // --------------------------------------------
                  TextFormField(
                    controller: username,
                    decoration: _inputDecoration('Username'),
                    validator: (v) =>
                        v!.isEmpty ? "please fill your informations" : null,
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------
                  // Password field + Eye icon toggle
                  // --------------------------------------------
                  TextFormField(
                    controller: password,
                    obscureText: obsPassword,
                    decoration: _passwordDecoration(
                      'Password',
                      obsPassword,
                      () => setState(() => obsPassword = !obsPassword),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return "please fill your informations";

                      /// Minimum password strength rule
                      if (v.length < 6) {
                        return "password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------
                  // Confirm password field + Eye icon toggle
                  // --------------------------------------------
                  TextFormField(
                    controller: confirmPassword,
                    obscureText: obsConfirm,
                    decoration: _passwordDecoration(
                      'Confirm Password',
                      obsConfirm,
                      () => setState(() => obsConfirm = !obsConfirm),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return "please fill your informations";

                      /// Ensure confirmation matches password
                      if (v != password.text) {
                        return "passwords do not match";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------
                  // Super Admin Password field
                  // --------------------------------------------
                  /// This field is used to restrict account creation
                  /// Only super admin can create new users.
                  TextFormField(
                    controller: superAdminPassword,
                    obscureText: true,
                    decoration: _inputDecoration('Super Admin Password'),
                    validator: (v) => v!.isEmpty
                        ? "super admin password is required"
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------
                  // Register button
                  // --------------------------------------------
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
                        /// Validate all form fields
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                        }

                        /// Later API integration:
                        /// - verify super admin password
                        /// - create new user
                        /// - show errors if invalid

                        if (success) {
                          /// Replace current screen with dashboard
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        }
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------
                  // Back to login
                  // --------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.blue),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text("Sign In"),
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
  }

  // ==========================================================
  // STYLING HELPERS (UI CONSISTENCY)
  // ==========================================================

  /// Input decoration for normal text fields
  /// Uses the same dark filled design as your app theme
  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF1C2B3A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  /// Input decoration for password fields
  /// Adds suffix icon (eye) to toggle visibility
  static InputDecoration _passwordDecoration(
    String label,
    bool obs,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF1C2B3A),

      /// Eye icon for show/hide password
      suffixIcon: IconButton(
        icon: Icon(obs ? Icons.visibility : Icons.visibility_off),
        onPressed: toggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
