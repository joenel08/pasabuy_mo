import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _codeLen = 6;

  final _form = GlobalKey<FormState>();
  final _codeCtrls = List.generate(_codeLen, (_) => TextEditingController());
  final _codeFocuses = List.generate(_codeLen, (_) => FocusNode());
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _codeCtrls) c.dispose();
    for (final f in _codeFocuses) f.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _code => _codeCtrls.map((c) => c.text).join();

  void _onCodeChanged(int i, String v) {
    if (v.length == 1 && i < _codeLen - 1) {
      _codeFocuses[i + 1].requestFocus();
    }
    if (v.isEmpty && i > 0) {
      _codeFocuses[i - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_code.length != _codeLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 6-digit code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthController>().resetPassword(
            email: widget.email,
            code: _code,
            newPassword: _newPass.text,
            newPasswordConfirmation: _confirmPass.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset! Sign in with your new password.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : 'Could not reset password';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _cooldown = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });

    try {
      await context.read<AuthController>().forgotPassword(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : 'Could not resend';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Code boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_codeLen, (i) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _codeCtrls[i],
                        focusNode: _codeFocuses[i],
                        onChanged: (v) => _onCodeChanged(i, v),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.borderSoft,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                _Label('New password'),
                TextFormField(
                  controller: _newPass,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _Label('Confirm new password'),
                TextFormField(
                  controller: _confirmPass,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newPass.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Reset password'),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't get a code? ",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _cooldown > 0 ? null : _resend,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
}