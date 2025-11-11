import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  DateTime? _selectedDate;
  String _gender = 'Male';
  String? _errorMessage;
  Country? _selectedCountry;

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedCountry = Country(
      phoneCode: '254',
      countryCode: 'KE',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'Kenya',
      example: 'Kenya',
      displayName: 'Kenya',
      displayNameNoCountryCode: 'KE',
      e164Key: '',
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(fullNameController.text.trim());
        
        // Send email verification
        await user.sendEmailVerification();

        // Get current timestamp in UTC+3
        final now = DateTime.now().toUtc().add(const Duration(hours: 3));
        
        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullNameController.text.trim(),
          'username': usernameController.text.trim().toLowerCase(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'countryCode': _selectedCountry?.countryCode ?? 'KE',
          'birthDate': _selectedDate != null 
              ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0)
                  .toUtc()
                  .add(const Duration(hours: 3))
              : null,
          'gender': _gender,
          'createdAt': now,
          'verifiedAt': null, // Will be set when user verifies email
          'status': 'unverified', // Initial status
          'phoneVerified': false,
          'followersCount': 0,
          'followingCount': 0,
          'followers': [],
          'following': [],
        });

        // Sign out the user (they need to verify email first)
        await _auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please check your email for verification."),
              duration: Duration(seconds: 5),
            ),
          );
          
          // Navigate to login page with verification message
          Navigator.pushReplacementNamed(
            context, 
            '/login',
            arguments: {
              'verificationMessage': 'Please check your email inbox and spam folder for the verification link.'
            }
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Signup failed.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black),
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        const Text(
          "Create Your Account",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        // Full name
        TextFormField(
          controller: fullNameController,
          style: const TextStyle(color: Colors.black),
          decoration: _inputDecoration(label: "Full Name", icon: Icons.person),
          validator: (value) =>
              value!.isEmpty ? "Please enter your full name" : null,
        ),
        const SizedBox(height: 15),

        // Username
        TextFormField(
          controller: usernameController,
          style: const TextStyle(color: Colors.black),
          decoration:
              _inputDecoration(label: "Username", icon: Icons.alternate_email),
          validator: (value) {
            if (value!.isEmpty) return "Username is required";
            if (value.contains(' ')) return "No spaces allowed";
            if (value.length < 4) return "At least 4 characters";
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Email
        TextFormField(
          controller: emailController,
          style: const TextStyle(color: Colors.black),
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(label: "Email", icon: Icons.email),
          validator: (value) {
            if (value!.isEmpty) return "Email is required";
            if (!value.contains('@')) return "Please enter a valid email";
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Password
        TextFormField(
          controller: passwordController,
          style: const TextStyle(color: Colors.black),
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            label: "Password",
            icon: Icons.lock,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.blue,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) return "Password is required";
            if (value.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Phone row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    countryListTheme: CountryListThemeData(
                      backgroundColor: Colors.white,
                      textStyle: const TextStyle(color: Colors.black),
                      bottomSheetHeight: 500,
                    ),
                    onSelect: (Country country) {
                      setState(() => _selectedCountry = country);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: Text(
                    '+${_selectedCountry?.phoneCode ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: phoneController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.phone,
                decoration:
                    _inputDecoration(label: "Phone Number", icon: Icons.phone),
                validator: (value) {
                  if (value!.isEmpty) return "Phone number is required";
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 7 || digits.length > 15) {
                    return "Enter a valid phone number";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Birth date
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration:
                _inputDecoration(label: "Birth Date", icon: Icons.calendar_today),
            child: Text(
              _selectedDate == null
                  ? "Select your birth date"
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey.shade600
                    : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Gender
        DropdownButtonFormField<String>(
          value: _gender,
          decoration:
              _inputDecoration(label: "Gender", icon: Icons.person_outline),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black),
          items: ['Male', 'Female', 'Other']
              .map(
                (gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(
                    gender,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _gender = value ?? 'Male'),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 30),

        // Signup button
        ElevatedButton(
          onPressed: _isLoading ? null : _signupUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  "SIGN UP",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
        const SizedBox(height: 20),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Already have an account?",
              style: TextStyle(color: Colors.black54),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                "Log In",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: Form(key: _formKey, child: _buildSignupForm()),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}