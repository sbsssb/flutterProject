import 'package:flutter/material.dart';
import 'festival_model.dart';

class FestivalCard extends StatelessWidget {
  final Festival festival;

  const FestivalCard({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          festival.imageUrl.isNotEmpty
              ? Image.network(
            festival.imageUrl,
            width: double.infinity,
            height: 168,
            fit: BoxFit.cover,
          )
              : Container(
            height: 168,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  festival.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(festival.address),
                const SizedBox(height: 2),
                Text(festival.tel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}