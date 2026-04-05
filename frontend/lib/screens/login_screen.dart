import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
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
  String? _otpCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
    if (_otpEmailController.text.trim().isEmpty) return;
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon in gradient circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTokens.primaryGradient,
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('Smart Expense Manager',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('AI-Powered Expense Tracking',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 28),

                  // Toggle buttons
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _tabController.animateTo(0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                    ? AppTokens.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _tabController.index == 0
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _tabController.animateTo(1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                    ? AppTokens.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'OTP Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _tabController.index == 1
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(auth.error!,
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13))),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Tab content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: IndexedStack(
                      index: _tabController.index,
                      children: [
                        _buildPasswordTab(),
                        _buildOtpTab(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick logins - demoted to text buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => _quickLogin('MC', 'MC'),
                          child: Text('Demo (MC)',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600)),
                        ),
                      ),
                      Text(' | ',
                          style: TextStyle(color: Colors.grey.shade400)),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => _quickLogin('dev', 'dev'),
                          child: Text('Dev Login',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child:
                        const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
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
            builder: (context, auth, _) => GradientButton(
              onPressed: auth.isLoading ? null : _signIn,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In'),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _otpEmailController,
            decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          if (!_otpSent)
            Consumer<AuthProvider>(
              builder: (context, auth, _) => GradientButton(
                onPressed: auth.isLoading ? null : _requestOtp,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text('Send OTP'),
                        ],
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
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your OTP: $_otpCode',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _otpCodeController,
              decoration: const InputDecoration(
                  labelText: '6-Digit Code',
                  prefixIcon: Icon(Icons.pin_outlined)),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter OTP';
                if (v.length != 6) return 'Must be 6 digits';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => GradientButton(
                onPressed: auth.isLoading ? null : _verifyOtp,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Verify & Sign In'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() {
                _otpSent = false;
                _otpCode = null;
                _otpCodeController.clear();
              }),
              child:
                  const Text('Resend OTP', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
