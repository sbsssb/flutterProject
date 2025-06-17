import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('임시 메인 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/addRoom');
              },
              child: const Text("방 만들기"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/festival');
              },
              child: const Text("축제 페이지"),
            ),

          ],
        ),
      ),
    );
  }
}
