import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class AuthorizedScreen extends StatelessWidget {
  const AuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = ModalRoute.of(context)!.settings.arguments as String? ?? 'unknown';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorized'),
        backgroundColor: const Color(0xFFFF8A65),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          )
        ],
      ),
      body: Center(
        child: Text('User id: $userId\nAuthorized', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}