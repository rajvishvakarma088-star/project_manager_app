import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _nameError {
    if (!_submitted) return null;
    if (_name.text.trim().isEmpty) return 'Full name is required';
    if (_name.text.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? get _emailError {
    if (!_submitted) return null;
    final value = _email.text.trim();
    if (value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? get _passwordError {
    if (!_submitted) return null;
    final value = _password.text;
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp('[A-Z]').hasMatch(value)) {
      return 'Password needs one uppercase letter';
    }
    if (!RegExp('[0-9]').hasMatch(value)) return 'Password needs one number';
    return null;
  }

  String? get _confirmError {
    if (!_submitted && _confirm.text.isEmpty) return null;
    if (_confirm.text != _password.text) return 'Passwords must match';
    return null;
  }

  Future<void> _signUp() async {
    setState(() => _submitted = true);
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await context.read<AuthService>().signUp(
        _email.text,
        _password.text,
      );
      await credential.user?.updateDisplayName(_name.text.trim());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not create account')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _confirm.text.isNotEmpty && _confirm.text == _password.text;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.fabGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Create account',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Start managing your tasks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'FULL NAME',
                      controller: _name,
                      hintText: 'Full name',
                      leadingIcon: Icons.person_outline_rounded,
                      errorText: _nameError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'EMAIL ADDRESS',
                      controller: _email,
                      hintText: 'Email address',
                      leadingIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'PASSWORD',
                      controller: _password,
                      hintText: 'Password',
                      leadingIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      errorText: _passwordError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'CONFIRM PASSWORD',
                      controller: _confirm,
                      hintText: 'Confirm password',
                      leadingIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      errorText: _confirmError,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_confirm.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            matches
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            color: matches
                                ? AppColors.success
                                : AppColors.error,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            matches
                                ? 'Passwords match'
                                : 'Passwords must match',
                            style: TextStyle(
                              color: matches
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Already have one? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
