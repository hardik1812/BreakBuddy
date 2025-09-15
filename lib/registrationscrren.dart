import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Use 'late final' for instances that are initialized once and never change.
  late final FirebaseFirestore _db;
  late final FirebaseAuth _auth;

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;

    // Listeners to rebuild for suffix icon visibility.
    // A more optimized approach for complex UIs would be ValueListenableBuilder.
    _idController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    // Check if the widget is still in the tree before showing a SnackBar.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registerUser() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String name = _nameController.text.trim();
      final String id = _idController.text.trim().toUpperCase();

      // 1. Create user with Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed, please try again.');
      }

      // 2. Update user profile and save additional data to Firestore
      await user.updateDisplayName(name);

      // Store non-auth related info in Firestore.
      // Email is already managed by Firebase Auth, storing it here is redundant.
      await _db.collection('users').doc(user.uid).set({
        'id': id,
        'name': name,
        // 'email': email, // This is redundant. Use user.email from FirebaseAuth.
      });

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeApp()), // Assuming HomeApp is a const constructor
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'An unknown authentication error occurred.');
    } on FirebaseException catch (e) {
      _showErrorSnackBar("Failed to save data: ${e.message}");
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Image.asset(
                    r'Assets\animations\Animation - 1750850468969.gif',
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_add,
                          size: 150, color: Colors.grey);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create a New Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildIdField(),
                  const SizedBox(height: 16),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 30),
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildLoginNavigation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdField() {
    return TextFormField(
      controller: _idController,
      decoration: _buildInputDecoration(
        hintText: 'Registration ID',
        prefixIcon: Icons.badge,
        controller: _idController,
      ),
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        LengthLimitingTextInputFormatter(9),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your Registration ID';
        }
        // Case-insensitive regex check for better UX.
        if (!RegExp(r'^\d{2}[a-z]{3}\d{4}$', caseSensitive: false)
            .hasMatch(value.trim())) {
          return 'Format: 2 digits, 3 letters, 4 digits (e.g., 25BAI1700)';
        }
        return null;
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: _buildInputDecoration(
        hintText: 'Name',
        prefixIcon: Icons.person,
        controller: _nameController,
      ),
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      autofillHints: const [AutofillHints.name],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _buildInputDecoration(
        hintText: 'Email Address',
        prefixIcon: Icons.email,
        controller: _emailController,
      ),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: _buildInputDecoration(
        hintText: 'Password',
        prefixIcon: Icons.lock,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: _buildInputDecoration(
        hintText: 'Confirm Password',
        prefixIcon: Icons.lock_clock,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isLoading ? null : _registerUser,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Register',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
      ),
    );
  }

  Widget _buildLoginNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          child: const Text(
            'Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ],
    );
  }

  // Helper method to reduce decoration boilerplate
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    TextEditingController? controller,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      prefixIcon: Icon(prefixIcon),
      hintText: hintText,
      suffixIcon: (controller != null && controller.text.isNotEmpty)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            )
          : null,
    );
  }
}