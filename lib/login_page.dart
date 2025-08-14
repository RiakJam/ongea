// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({Key? key}) : super(key: key);

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   // Controllers
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   final resetEmailController = TextEditingController();

//   /// ✅ Login with Email and Password
//   Future<void> _login() async {
//     setState(() => _isLoading = true);
//     try {
//       await _auth.signInWithEmailAndPassword(
//         email: usernameController.text.trim(),
//         password: passwordController.text.trim(),
//       );
//       Navigator.pushReplacementNamed(context, '/home');
//     } on FirebaseAuthException catch (e) {
//       _showSnackBar(e.message ?? "Login failed");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   /// ✅ Forgot Password Modal
//   void _showResetPasswordModal() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Reset Password"),
//         content: TextField(
//           controller: resetEmailController,
//           decoration: const InputDecoration(
//             labelText: "Enter your email",
//             border: OutlineInputBorder(),
//           ),
//           keyboardType: TextInputType.emailAddress,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: _resetPassword,
//             child: const Text("Send Reset Link"),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ✅ Send Reset Password Email
//   Future<void> _resetPassword() async {
//     if (resetEmailController.text.isEmpty) {
//       _showSnackBar("Please enter your email");
//       return;
//     }
//     try {
//       await _auth.sendPasswordResetEmail(email: resetEmailController.text.trim());
//       Navigator.pop(context);
//       _showSnackBar("Password reset link sent to your email");
//     } catch (e) {
//       _showSnackBar("Error: $e");
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   void dispose() {
//     usernameController.dispose();
//     passwordController.dispose();
//     resetEmailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Login"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Welcome Back!",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 // Username Field
//                 TextFormField(
//                   controller: usernameController,
//                   decoration: InputDecoration(
//                     labelText: "Email or Phone Number",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.person),
//                   ),
//                   validator: (value) =>
//                       value!.isEmpty ? "Please enter your email or phone" : null,
//                 ),
//                 const SizedBox(height: 15),

//                 // Password Field
//                 TextFormField(
//                   controller: passwordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: "Password",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.lock),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                     ),
//                   ),
//                   validator: (value) =>
//                       value!.isEmpty ? "Please enter your password" : null,
//                 ),
//                 const SizedBox(height: 10),

//                 // Forgot Password Button
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: _showResetPasswordModal,
//                     child: const Text(
//                       "Forgot Password?",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Login Button
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : () {
//                     if (_formKey.currentState!.validate()) {
//                       _login();
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           "LOGIN",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Signup Redirect
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Don't have an account?"),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacementNamed(context, '/signup');
//                       },
//                       child: const Text(
//                         "Sign Up",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;

  String _generatedOtp = "";

  // Controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();

  /// ✅ Login with Email and Password
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Login failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Generate and Send OTP (Mock)
  Future<void> _generateAndSendOtp(StateSetter setStateDialog) async {
    final email = resetEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email");
      return;
    }

    _generatedOtp = (100000 + Random().nextInt(900000)).toString();
    print("DEBUG OTP: $_generatedOtp"); // Simulated OTP for testing

    setStateDialog(() {
      _isOtpSent = true;
    });

    _showSnackBar("OTP sent to $email");
  }

  /// ✅ Verify OTP
  void _verifyOtp(StateSetter setStateDialog) {
    if (otpController.text.trim() == _generatedOtp) {
      setStateDialog(() {
        _isOtpVerified = true;
      });
      _showSnackBar("OTP verified. Proceed to reset password.");
    } else {
      _showSnackBar("Invalid OTP. Please try again.");
    }
  }

  /// ✅ Simulated Password Reset
  Future<void> _updatePassword() async {
    try {
      await _auth.sendPasswordResetEmail(
        email: resetEmailController.text.trim(),
      );
      _showSnackBar("Reset email sent. Check your inbox.");
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  /// ✅ Reset Modal
  void _showResetPasswordModal() {
    // Reset state for modal
    resetEmailController.clear();
    otpController.clear();
    newPasswordController.clear();
    _isOtpSent = false;
    _isOtpVerified = false;
    _generatedOtp = "";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Reset Password"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: resetEmailController,
                  decoration: const InputDecoration(
                    labelText: "Enter your email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                if (_isOtpSent)
                  TextField(
                    controller: otpController,
                    decoration: const InputDecoration(
                      labelText: "Enter OTP",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_isOtpSent) const SizedBox(height: 10),

                if (_isOtpVerified)
                  TextField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: "New Password (Note: Simulated)",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (!_isOtpSent)
              ElevatedButton(
                onPressed: () => _generateAndSendOtp(setStateDialog),
                child: const Text("Send OTP"),
              ),
            if (_isOtpSent && !_isOtpVerified)
              ElevatedButton(
                onPressed: () => _verifyOtp(setStateDialog),
                child: const Text("Verify OTP"),
              ),
            if (_isOtpVerified)
              ElevatedButton(
                onPressed: _updatePassword,
                child: const Text("Send Reset Email"),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ SnackBar Utility
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email / Phone Field
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter your email" : null,
                ),
                const SizedBox(height: 15),

                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter your password" : null,
                ),
                const SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordModal,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 20),

                // Sign Up Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Continue as Guest
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                    "Continue as Guest",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

