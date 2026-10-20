import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text('Verification Pending',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Our admin team is reviewing your submitted ID. '
                'You will be notified once approved.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () async {
                  await context.read<AuthController>().refreshMe();
                  if (context.mounted) context.go('/');
                },
                child: const Text('Check status'),
              ),
              TextButton(
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