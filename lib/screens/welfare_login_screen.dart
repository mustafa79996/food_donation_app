import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/admin_config.dart';
import '../utils/routes.dart';

class WelfareLoginScreen extends StatefulWidget {
  const WelfareLoginScreen({super.key});

  @override
  State<WelfareLoginScreen> createState() => _WelfareLoginScreenState();
}

class _WelfareLoginScreenState extends State<WelfareLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter email and password');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('The account could not be loaded.');
      }

      // Check if logged in as Admin (mustafa79996@gmail.com)
      if (isWelfareAdmin(user)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in as Welfare Administrator'),
            backgroundColor: Color(0xFF1E7D45),
          ),
        );
        Navigator.pushReplacementNamed(context, Routes.welfareVerification);
        return;
      }

      // Check welfare centre registration
      final docRef = FirebaseFirestore.instance
          .collection('welfare_centres')
          .doc(user.uid);
      final snapshot = await docRef.get();
      Map<String, dynamic>? data = snapshot.data();

      // If document was not found by UID, search by email as fallback
      if (!snapshot.exists || data == null) {
        final query = await FirebaseFirestore.instance
            .collection('welfare_centres')
            .where('email', isEqualTo: user.email?.trim().toLowerCase())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          data = query.docs.first.data();
        }
      }

      if (data == null) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _showMessage(
            'No welfare centre registration found for this account. Please submit an application first.',
          );
        }
        return;
      }

      final status = (data['status'] as String? ?? 'pending').toLowerCase();
      final certificatePath = data['certificatePath'] as String? ?? '';

      if (status == 'approved') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${data['name'] ?? 'Welfare Centre'}!'),
              backgroundColor: const Color(0xFF1E7D45),
            ),
          );
          Navigator.pushReplacementNamed(context, Routes.welfareDashboard);
        }
      } else if (status == 'pending') {
        if (certificatePath.isEmpty) {
          if (mounted) {
            await Navigator.pushNamed(context, Routes.welfareRegistration);
            if (FirebaseAuth.instance.currentUser?.uid == user.uid) {
              await FirebaseAuth.instance.signOut();
            }
          }
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showPendingDialog();
          }
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _showMessage(
            'Your application was not approved. Please contact mustafa79996@gmail.com for details.',
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Unable to sign in.');
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage('Verification error: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to sign in: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.orange),
            SizedBox(width: 8),
            Text('Application Pending'),
          ],
        ),
        content: const Text(
          'Your welfare centre registration is pending approval by the administrator (mustafa79996@gmail.com).\n\n'
          'Once approved, you will be able to log in and access the Welfare Dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      appBar: AppBar(title: const Text('Welfare Centre Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E7D45).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  size: 70,
                  color: Color(0xFF1E7D45),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welfare Centre Login',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in for approved welfare centres and administrator',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Welfare Centre or Admin Email',
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
                      : const Text('Login as Welfare Centre'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          Routes.welfareRegistration,
                        ),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Apply as a Welfare Centre'),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to User Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
