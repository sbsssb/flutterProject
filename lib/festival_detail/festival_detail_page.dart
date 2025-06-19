import 'package:flutter/material.dart';
import 'festival_detail_api.dart';
import 'festival_detail_model.dart';
import 'package:url_launcher/url_launcher.dart';

String formatDate(String raw) {
  if (raw.length != 8) return raw;
  final year = raw.substring(0, 4);
  final month = raw.substring(4, 6);
  final day = raw.substring(6, 8);
  return '$year.$month.$day';
}

String extractUrl(String html) {
  final match = RegExp(r'href="([^"]+)"').firstMatch(html);
  return match?.group(1) ?? '';
}

class FestivalDetailPage extends StatefulWidget {
  final String contentId;
  final int contentTypeId;

  const FestivalDetailPage({
    super.key,
    required this.contentId,
    required this.contentTypeId,
  });

  @override
  State<FestivalDetailPage> createState() => _FestivalDetailPageState();
}

class _FestivalDetailPageState extends State<FestivalDetailPage> {
  late Future<FestivalDetail?> futureDetail;

  @override
  void initState() {
    super.initState();
    futureDetail = FestivalDetailApi.fetchFestivalDetail(
        widget.contentId,
        widget.contentTypeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FestivalDetail?>(
      future: futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('데이터를 불러올 수 없습니다')),
          );
        }

        final detail = snapshot.data!;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  detail.imageUrls.isNotEmpty ? detail.imageUrls[0] : 'https://via.placeholder.com/600x400',
                  fit: BoxFit.cover,
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          detail.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${formatDate(detail.eventStartDate)} ~ ${formatDate(detail.eventEndDate)}'),
                        const SizedBox(height: 16),
                        if (detail.imageUrls.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: PageView.builder(
                              itemCount: detail.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      detail.imageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.image_not_supported));
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        buildInfoCard("📍 장소", detail.eventPlace),
                        buildInfoCard("⏰ 시간", detail.playTime),
                        buildInfoCard("💰 요금", detail.useTimeFestival),
                        buildInfoCard("🔗 예매", detail.bookingPlace),
                        buildInfoCard("🎟️ 할인", detail.discountInfoFestival),
                        buildInfoCard("🏢 주최", detail.sponsor),
                        buildInfoCard("📞 연락처", detail.tel),
                        buildInfoCard("🏠 주소", detail.address),
                        if (detail.homepage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🌐 홈페이지: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final url = extractUrl(detail.homepage);
                                      if (url.isNotEmpty) launchUrl(Uri.parse(url));
                                    },
                                    child: Text(
                                      extractUrl(detail.homepage),
                                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(detail.overview),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildInfoCard(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }
}