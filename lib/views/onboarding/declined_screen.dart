import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class DeclinedScreen extends StatelessWidget {
  const DeclinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text('Verification Declined',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Your submission was declined. '
                'Please contact support or re-submit with clearer documents.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () => context.read<AuthController>().logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}