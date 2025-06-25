import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userId;

  const CustomAppBar({super.key, required this.userId});

  Future<void> handleLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        for (var info in user.providerData) {
          if (info.providerId == 'google.com') {
            await GoogleSignIn().signOut();
            break;
          }
        }

        await FirebaseAuth.instance.signOut();
      }

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading:
          Navigator.canPop(context)
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
              : null,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Image.asset('assets/mypage_images/logo.png', height: 60)],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: (){
                handleLogout(context);
              }
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
