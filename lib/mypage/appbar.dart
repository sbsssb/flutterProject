import 'package:flutter/material.dart';
import 'appbar.dart';

PreferredSizeWidget buildAppBar({
  required int unreadCount,
  required VoidCallback onNotificationTap,
}) {
  return AppBar(
    centerTitle: false,
    title: Padding(
      padding: const EdgeInsets.only(left: 100.0, top: 11.0),
      child: Image.asset(
        'assets/logo.png',
        height: 70,
      ),
    ),
    actions: [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: onNotificationTap,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}