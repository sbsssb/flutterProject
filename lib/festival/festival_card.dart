import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'festival_model.dart';

class FestivalCard extends StatelessWidget {
  final Festival festival;

  const FestivalCard({super.key, required this.festival});

  String formatDate(String yyyymmdd) {
    if (yyyymmdd.length != 8) return yyyymmdd;

    final year = yyyymmdd.substring(0, 4);
    final month = yyyymmdd.substring(4, 6);
    final day = yyyymmdd.substring(6, 8);

    return '$year.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('👉 카드 클릭됨: contentId = ${festival.contentId}');
        context.push('/festivalDetail/${festival.contentId}?type=${festival.contentTypeId}');
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: festival.imageUrl.isNotEmpty
                    ? Image.network(
                  festival.imageUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        festival.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatDate(festival.eventStartDate)} ~ ${formatDate(festival.eventEndDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        festival.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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