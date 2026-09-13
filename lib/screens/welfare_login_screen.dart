import 'package:flutter/material.dart';

import '../utils/routes.dart';

class WelfareLoginScreen extends StatefulWidget {
  const WelfareLoginScreen({super.key});

  @override
  State<WelfareLoginScreen> createState() =>
      _WelfareLoginScreenState();
}

class _WelfareLoginScreenState
    extends State<WelfareLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    // Temporary test login.
    // Firebase welfare authentication can be added after
    // the separate screen is working.

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      Navigator.pushReplacementNamed(
        context,
        Routes.welfareDashboard,
      );
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Centre Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              const Icon(
                Icons.business,
                size: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                'Welfare Centre Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                'Login for registered welfare centres',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Welfare Centre Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : login,
                  icon: const Icon(Icons.login),
                  label: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login as Welfare Centre',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}