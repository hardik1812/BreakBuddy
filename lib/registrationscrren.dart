import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override

  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {

  FirebaseFirestore db = FirebaseFirestore.instance;
  // 1. State Management & Form Validation
  final _idController=TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 2. UI State Variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Rebuilds the widget to show/hide the clear button on the fields
    _idController.addListener(()=> setState(() {
      
    }));
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // 3. Dispose controllers to prevent memory leaks
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 4. Asynchronous Registration Logic with Error Handling
  Future<void> _registerUser() async {
    // Validate the form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Create user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = userCredential.user;
      if (user == null) {
        // This is unlikely, but handle it just in case.
        throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User creation failed, please try again.');
      }

      // Update user's display name and store other info in Firestore
      await user.updateDisplayName(_nameController.text.trim());
      await db.collection('users').doc(user.uid).set({
        'id': _idController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      await user.reload(); // Reload user to get updated info

      // Check if the widget is still in the tree before navigating
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeApp()),
        (route) => false, // Removes all previous routes
      );
    } on FirebaseAuthException catch (e) {
      // Use the message from the exception directly for more specific feedback
      Fluttertoast.showToast(
          msg: e.message ?? 'An unknown authentication error occurred.',
          backgroundColor: Colors.red);
    } on FirebaseException catch (e) {
      // Catches Firestore-specific errors, e.g., permission denied
      Fluttertoast.showToast(
          msg: "Failed to save data: ${e.message}",
          backgroundColor: Colors.red);
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'An unexpected error occurred: $e', backgroundColor: Colors.red);
    } finally {
      // Ensure loading state is always turned off
      if(mounted) {
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
        // 5. Use SingleChildScrollView to prevent overflow
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
                  // 6. Replaced Lottie with a static Image asset
                  Image.asset(
                    r'Assets\animations\Animation - 1750850468969.gif', // **IMPORTANT: Change this to your actual image path**
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_add, size: 150, color: Colors.grey); // Placeholder on error
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create a New Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                    const SizedBox(height: 30),
                    TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Registration ID',
                      suffixIcon: _idController.text.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _idController.clear(),
                        ),
                    ),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(9),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                      // Always convert to uppercase
                      return TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      );
                      }),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                      return 'Please enter your Registration ID';
                      }
                      // Must match: 2 digits, 3 uppercase letters, 4 digits
                      if (!RegExp(r'^\d{2}[A-Z]{3}\d{4}$').hasMatch(value.trim())) {
                      return 'Format: 2 digits, 3 capital letters, 4 digits (e.g. 25BAI1700)';
                      }
                      return null;
                    },
                    ),
                  const SizedBox(height: 16),
                  // Name TextFormField
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Name',
                      suffixIcon: _nameController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _nameController.clear(),
                            ),
                    ),
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email TextFormField
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'Email Address',
                       suffixIcon: _emailController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _emailController.clear(),
                            ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                     validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password TextFormField
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
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
                  ),
                   const SizedBox(height: 16),

                  // 7. Added Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.lock_clock),
                      hintText: 'Confirm Password',
                       suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
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
                  ),
                  const SizedBox(height: 30),

                  // 8. Loading state in Button
                  SizedBox(
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
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Navigation to Login
                  Row(
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
                            MaterialPageRoute(
                                builder: (context) => const Login()),
                          );
                        },
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