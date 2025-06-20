import 'package:flutter/material.dart';
import '../common/bottom_nav_bar.dart';
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

String stripHtmlTags(String htmlText) {
  return htmlText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
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
  int _currentPage = 0;

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
          bottomNavigationBar: const BottomNavBar(),
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
                          style: const TextStyle(
                            fontFamily: 'Jalnan',
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${formatDate(detail.eventStartDate)} ~ ${formatDate(detail.eventEndDate)}',
                          style: const TextStyle(fontFamily: 'AstaSans'),
                        ),
                        const SizedBox(height: 16),
                        if (detail.imageUrls.isNotEmpty)
                          Stack(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PageView.builder(
                                  itemCount: detail.imageUrls.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
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
                              Positioned(
                                bottom: 8,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${_currentPage + 1} / ${detail.imageUrls.length}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        const SizedBox(height: 16),
                        buildInfoCard("\uD83D\uDCCD 장소", detail.eventPlace),
                        buildInfoCard("\u23F0 시간", stripHtmlTags(detail.playTime)),
                        buildInfoCard("\uD83D\uDCB0 요금", stripHtmlTags(detail.useTimeFestival)),
                        buildInfoCard("\uD83D\uDD17 예매", stripHtmlTags(detail.bookingPlace)),
                        buildInfoCard("\uD83C\uDF9F\uFE0F 할인", stripHtmlTags(detail.discountInfoFestival)),
                        buildInfoCard("\uD83C\uDFE2 주최", detail.sponsor),
                        buildInfoCard("\uD83D\uDCDE 연락처", detail.tel),
                        buildInfoCard("\uD83C\uDFE0 주소", detail.address),
                        if (detail.homepage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '\uD83C\uDF10 홈페이지: ',
                                  style: TextStyle(
                                    fontFamily: 'AstaSans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final url = extractUrl(detail.homepage);
                                      if (url.isNotEmpty) launchUrl(Uri.parse(url));
                                    },
                                    child: Text(
                                      extractUrl(detail.homepage),
                                      style: TextStyle(
                                        fontFamily: 'AstaSans',
                                        color: Theme.of(context).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          stripHtmlTags(detail.overview),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'AstaSans',
                          ),
                        ),
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
          Text(
            '$title: ',
            style: const TextStyle(
              fontFamily: 'AstaSans',
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'AstaSans'),
            ),
          )
        ],
      ),
    );
  }
}