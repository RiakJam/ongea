// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:country_picker/country_picker.dart';

// class SignupPage extends StatefulWidget {
//   const SignupPage({Key? key}) : super(key: key);

//   @override
//   State<SignupPage> createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//   DateTime? _selectedDate;
//   String _gender = 'Male';
//   String? _verificationId;
//   Country? _selectedCountry;

//   // Controllers
//   final fullNameController = TextEditingController();
//   final usernameController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final phoneController = TextEditingController();
//   final otpController = TextEditingController();

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     // Set default country (optional)
//     _selectedCountry = Country(
//       phoneCode: '1',
//       countryCode: 'US',
//       e164Sc: 0,
//       geographic: true,
//       level: 1,
//       name: 'United States',
//       example: 'United States',
//       displayName: 'United States',
//       displayNameNoCountryCode: 'US',
//       e164Key: '',
//     );
//   }

//   Future<void> _registerUser() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);
//     try {
//       await _verifyPhoneNumber();
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _verifyPhoneNumber() async {
//     if (_selectedCountry == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please select a country")));
//       return;
//     }

//     String fullPhoneNumber =
//         '+${_selectedCountry!.phoneCode}${phoneController.text.trim()}';

//     await _auth.verifyPhoneNumber(
//       phoneNumber: fullPhoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await _auth.signInWithCredential(credential);
//         await _completeRegistration(_auth.currentUser!);
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Verification failed: ${e.message}")),
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//         });
//         _showOtpDialog();
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         setState(() => _verificationId = verificationId);
//       },
//       timeout: const Duration(seconds: 60),
//     );
//   }

//   void _showOtpDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Verify Your Phone"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "We've sent an SMS with a verification code to your phone.",
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "OTP Code",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: _verifyPhoneOtp,
//             child: const Text("Verify"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _verifyPhoneOtp() async {
//     setState(() => _isLoading = true);
//     try {
//       AuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otpController.text.trim(),
//       );

//       UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );
//       await _completeRegistration(userCredential.user!);

//       Navigator.pop(context); // Close OTP dialog
//       Navigator.pushReplacementNamed(context, '/login');
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Invalid OTP: ${e.toString()}")));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _completeRegistration(User user) async {
//     final userData = {
//       'uid': user.uid,
//       'fullName': fullNameController.text.trim(),
//       'username': usernameController.text.trim().toLowerCase(),
//       'email': emailController.text.trim().isNotEmpty
//           ? emailController.text.trim()
//           : null,
//       'phone': '+${_selectedCountry!.phoneCode}${phoneController.text.trim()}',
//       'countryCode': _selectedCountry!.countryCode,
//       'birthDate': _selectedDate,
//       'gender': _gender,
//       'createdAt': FieldValue.serverTimestamp(),
//       'followers': 0,
//       'following': 0,
//       'engagementScore': 0,
//       'contentPreferences': [],
//       'lastActive': FieldValue.serverTimestamp(),
//       'phoneVerified': true,
//     };

//     await _firestore.collection('users').doc(user.uid).set(userData);

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Registration successful!")));
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       initialEntryMode: DatePickerEntryMode.input,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             datePickerTheme: const DatePickerThemeData(
//               headerHelpStyle: TextStyle(fontSize: 16),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() => _selectedDate = picked);
//     }
//   }

//   @override
//   void dispose() {
//     fullNameController.dispose();
//     usernameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     phoneController.dispose();
//     otpController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Create Account"),
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
//                   "Join Our Community",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 // Full Name
//                 TextFormField(
//                   controller: fullNameController,
//                   decoration: InputDecoration(
//                     labelText: "Full Name",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.person),
//                   ),
//                   validator: (value) =>
//                       value!.isEmpty ? "Please enter your full name" : null,
//                 ),
//                 const SizedBox(height: 15),

//                 // Username
//                 TextFormField(
//                   controller: usernameController,
//                   decoration: InputDecoration(
//                     labelText: "Username",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.alternate_email),
//                   ),
//                   validator: (value) {
//                     if (value!.isEmpty) return "Username is required";
//                     if (value.contains(' ')) return "No spaces allowed";
//                     if (value.length < 4) return "At least 4 characters";
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 15),

//                 // Email (Optional, just saved)
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     labelText: "Email (optional)",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.email),
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 // Phone Number with Country Picker
//                 // Phone Number with Country Picker
//                 Row(
//                   children: [
//                     Container(
//                       height: 60, // Match the height of TextFormField
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: InkWell(
//                         onTap: () {
//                           showCountryPicker(
//                             context: context,
//                             showPhoneCode: true,
//                             onSelect: (Country country) {
//                               setState(() {
//                                 _selectedCountry = country;
//                               });
//                             },
//                             countryListTheme: CountryListThemeData(
//                               borderRadius: BorderRadius.circular(10),
//                               inputDecoration: InputDecoration(
//                                 labelText: 'Search',
//                                 hintText: 'Start typing to search',
//                                 prefixIcon: const Icon(Icons.search),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             if (_selectedCountry != null)
//                               Text(
//                                 '+${_selectedCountry!.phoneCode}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             const SizedBox(width: 5),
//                             const Icon(Icons.arrow_drop_down),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: TextFormField(
//                         controller: phoneController,
//                         keyboardType: TextInputType.phone,
//                         decoration: InputDecoration(
//                           labelText: "Phone Number",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           prefixIcon: const Icon(Icons.phone),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 15,
//                           ), // Adjust vertical padding
//                         ),
//                         validator: (value) {
//                           if (value!.isEmpty) return "Phone number is required";
//                           if (!RegExp(r'^[0-9]{7,15}$').hasMatch(value)) {
//                             return "Enter a valid phone number";
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 15),

//                 // Password
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
//                         _obscurePassword
//                             ? Icons.visibility_off
//                             : Icons.visibility,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value!.isEmpty) return "Password is required";
//                     if (value.length < 6) return "At least 6 characters";
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 15),

//                 // Birth Date
//                 InkWell(
//                   onTap: () => _selectDate(context),
//                   child: InputDecorator(
//                     decoration: InputDecoration(
//                       labelText: "Birth Date (DD/MM/YYYY)",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       prefixIcon: const Icon(Icons.calendar_today),
//                     ),
//                     child: Text(
//                       _selectedDate == null
//                           ? "Select your birth date"
//                           : DateFormat('dd/MM/yyyy').format(_selectedDate!),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 // Gender
//                 DropdownButtonFormField<String>(
//                   value: _gender,
//                   decoration: InputDecoration(
//                     labelText: "Gender",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     prefixIcon: const Icon(Icons.person_outline),
//                   ),
//                   items: ['Male', 'Female', 'Other']
//                       .map(
//                         (gender) => DropdownMenuItem(
//                           value: gender,
//                           child: Text(gender),
//                         ),
//                       )
//                       .toList(),
//                   onChanged: (value) =>
//                       setState(() => _gender = value ?? 'Male'),
//                 ),
//                 const SizedBox(height: 30),

//                 // Sign Up Button
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _registerUser,
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
//                           "SIGN UP",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Login Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("Already have an account?"),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacementNamed(context, '/login');
//                       },
//                       child: const Text(
//                         "Log In",
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
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isResending = false;
  DateTime? _selectedDate;
  String _gender = 'Male';
  String? _verificationId;
  int? _resendToken;
  Country _selectedCountry = Country(
    phoneCode: '1',
    countryCode: 'US',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'United States',
    example: 'United States',
    displayName: 'United States',
    displayNameNoCountryCode: 'US',
    e164Key: '',
  );

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    await _verifyPhoneNumber();
  }

  Future<void> _verifyPhoneNumber() async {
    setState(() => _isLoading = true);
    
    try {
      final fullPhoneNumber = '+${_selectedCountry.phoneCode}${phoneController.text.trim()}';

      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      _showErrorSnackbar('Verification error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _completeRegistration(userCredential.user!);
      _navigateToLogin();
    } catch (e) {
      _showErrorSnackbar('Auto-verification failed: ${e.toString()}');
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    _showErrorSnackbar('Verification failed: ${e.message}');
    setState(() => _isLoading = false);
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      _isLoading = false;
    });
    _showOtpDialog();
  }

  void _onCodeTimeout(String verificationId) {
    setState(() => _verificationId = verificationId);
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Your Phone"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("We've sent an SMS with a verification code"),
            const SizedBox(height: 20),
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? "Enter OTP code" : null,
            ),
            TextButton(
              onPressed: _isResending ? null : _resendOtp,
              child: _isResending 
                  ? const CircularProgressIndicator()
                  : const Text("Resend OTP"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _verifyPhoneOtp,
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    await _verifyPhoneNumber();
    setState(() => _isResending = false);
  }

  Future<void> _verifyPhoneOtp() async {
    if (otpController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _completeRegistration(userCredential.user!);
      _navigateToLogin();
    } catch (e) {
      _showErrorSnackbar('Invalid OTP: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration(User user) async {
    final userData = {
      'uid': user.uid,
      'fullName': fullNameController.text.trim(),
      'username': usernameController.text.trim().toLowerCase(),
      'email': emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : null,
      'phone': '+${_selectedCountry.phoneCode}${phoneController.text.trim()}',
      'countryCode': _selectedCountry.countryCode,
      'birthDate': _selectedDate,
      'gender': _gender,
      'createdAt': FieldValue.serverTimestamp(),
      'phoneVerified': true,
    };

    await _firestore.collection('users').doc(user.uid).set(userData);
    _showSuccessSnackbar("Registration successful!");
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _navigateToLogin() {
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Join Our Community",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Full Name
              TextFormField(
                controller: fullNameController,
                decoration: _inputDecoration("Full Name", Icons.person),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // Username
              TextFormField(
                controller: usernameController,
                decoration: _inputDecoration("Username", Icons.alternate_email),
                validator: (value) {
                  if (value!.isEmpty) return "Required";
                  if (value.contains(' ')) return "No spaces allowed";
                  if (value.length < 4) return "Too short";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Email (Optional)
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email (optional)", Icons.email),
              ),
              const SizedBox(height: 15),

              // Phone Number
              Row(
                children: [
                  InkWell(
                    onTap: () => showCountryPicker(
                      context: context,
                      showPhoneCode: true,
                      onSelect: (country) => setState(() => _selectedCountry = country),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('+${_selectedCountry.phoneCode}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration("Phone Number", Icons.phone),
                      validator: (value) {
                        if (value!.isEmpty) return "Required";
                        if (!RegExp(r'^[0-9]{7,15}$').hasMatch(value)) {
                          return "Invalid number";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration("Password", Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword 
                        ? Icons.visibility_off 
                        : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Required";
                  if (value.length < 6) return "Too short";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Birth Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: _inputDecoration("Birth Date", Icons.calendar_today),
                  child: Text(
                    _selectedDate == null
                        ? "Select date"
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _inputDecoration("Gender", Icons.person_outline),
                items: ['Male', 'Female', 'Other'].map((gender) => 
                  DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ),
                ).toList(),
                onChanged: (value) => setState(() => _gender = value ?? 'Male'),
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("SIGN UP"),
              ),
              const SizedBox(height: 20),

              // Login Link
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Already have an account? Log In"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }
}