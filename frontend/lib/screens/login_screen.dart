import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _passwordFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpEmailController = TextEditingController();
  final _otpCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _otpSent = false;
  String? _otpCode; // For demo display

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpEmailController.dispose();
    _otpCodeController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _signIn() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) _navigateToDashboard();
  }

  Future<void> _quickLogin(String email, String password) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(email, password);
    if (success && mounted) _navigateToDashboard();
  }

  Future<void> _requestOtp() async {
    if (_otpEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final result = await auth.requestOtp(_otpEmailController.text.trim());
    if (result != null && mounted) {
      setState(() {
        _otpSent = true;
        _otpCode = result['otp']?.toString();
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      _otpEmailController.text.trim(),
      _otpCodeController.text.trim(),
    );
    if (success && mounted) _navigateToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 72, color: Theme.of(context).primaryColor),
                const SizedBox(height: 12),
                Text('Smart Expense Manager',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('AI-Powered Expense Tracking',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 32),

                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Password'),
                    Tab(text: 'OTP Login'),
                  ],
                  onTap: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Error display
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(auth.error!,
                                      style: const TextStyle(
                                          color: Colors.red))),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Tab content
                SizedBox(
                  height: _tabController.index == 0 ? 200 : (_otpSent ? 280 : 170),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPasswordTab(),
                      _buildOtpTab(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick login buttons
                Row(
                  children: [
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) => OutlinedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => _quickLogin('MC', 'MC'),
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Demo (MC)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) => OutlinedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => _quickLogin('dev', 'dev'),
                          icon: const Icon(Icons.code, size: 18),
                          label: const Text('Dev Login'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTab() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your password' : null,
          ),
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _signIn,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpTab() {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _otpEmailController,
            decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 12),
          if (!_otpSent)
            Consumer<AuthProvider>(
              builder: (context, auth, _) => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: auth.isLoading ? null : _requestOtp,
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Send OTP'),
                ),
              ),
            ),
          if (_otpSent) ...[
            if (_otpCode != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OTP sent! Your code: $_otpCode',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _otpCodeController,
              decoration: const InputDecoration(
                  labelText: '6-Digit OTP Code',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter the OTP code';
                if (v.length != 6) return 'Code must be 6 digits';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _verifyOtp,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify & Sign In',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _otpSent = false;
                _otpCode = null;
                _otpCodeController.clear();
              }),
              child: const Text('Resend OTP'),
            ),
          ],
        ],
      ),
    );
  }
}
