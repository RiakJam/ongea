import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home_feed_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final bool cameFromHomePage;
  final Map<String, dynamic>? arguments;

  const LoginPage({Key? key, this.cameFromHomePage = false, this.arguments}) : super(key: key);

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
  String? _verificationMessage;

  String _generatedOtp = "";

  // Controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if we have a verification message from signup
    _verificationMessage = widget.arguments?['verificationMessage'];
    
    // Show the verification message as a snackbar when the page loads
    if (_verificationMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(_verificationMessage!);
      });
    }
  }

  /// ✅ Login with Email and Password
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        _showSnackBar("Please verify your email before logging in. Check your inbox and spam folder.");
        await _auth.signOut(); // Sign out if email is not verified
        setState(() => _isLoading = false);
        return;
      }

      // Use different navigation based on where we came from
      if (widget.cameFromHomePage) {
        // If we came from HomePage, pop back to it
        Navigator.pop(context);
      } else {
        // If we came directly to LoginPage, navigate to HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeFeedPage()),
          (route) => false,
        );
      }
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

  /// ✅ Resend verification email
  Future<void> _resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackBar("Verification email sent. Please check your inbox and spam folder.");
      }
    } catch (e) {
      _showSnackBar("Error sending verification email: $e");
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
      ),
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
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blue,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
          leading: widget.cameFromHomePage
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification message banner (if any)
                  if (_verificationMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _verificationMessage!,
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.person),
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
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
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

                  // Resend verification email button
                  if (_verificationMessage != null) ...[
                    OutlinedButton(
                      onPressed: _resendVerificationEmail,
                      child: const Text("Resend Verification Email"),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sign Up Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
}