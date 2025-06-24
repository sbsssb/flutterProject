import 'package:flutter/material.dart';
import '../common/bottom_nav_bar.dart';
import '../utils/festival_top_bar.dart';
import 'festival_api.dart';
import 'festival_model.dart';
import 'festival_card.dart';
import 'festival_filter_bar.dart';
import 'package:flutterteam4/utils/festival_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class FestivalListPage extends StatefulWidget {
  const FestivalListPage({super.key});

  @override
  State<FestivalListPage> createState() => _FestivalListPageState();
}

class _FestivalListPageState extends State<FestivalListPage> {
  late String selectedDate;
  String selectedRegion = '';
  String selectedCategory = '';
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool isLastPage = false;

  late Future<List<Festival>> futureFestivals;
  List<Festival> allFestivals = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedDate = generateDateOptions().first;
    futureFestivals = fetchFestivals(
      eventStartDate: selectedDate,
      page: 1,
      numOfRows: 200,
    ).then((data) => _filterFestivalsByMonth(data));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Festival> _filterFestivalsByMonth(List<Festival> data) {
    final month = int.parse(selectedDate.substring(4, 6));
    final year = int.parse(selectedDate.substring(0, 4));
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);

    final filtered = data.where((f) {
      final start = DateTime.parse(f.eventStartDate);
      final end = DateTime.parse(f.eventEndDate);
      return !end.isBefore(monthStart) && !start.isAfter(monthEnd);
    }).toList();

    setState(() {
      allFestivals = filtered;
      isLastPage = filtered.length <= itemsPerPage;
    });

    return filtered;
  }

  void _fetchFiltered() {
    setState(() {
      currentPage = 1;
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        areaCode: selectedRegion,
        cat3: selectedCategory,
        page: 1,
        numOfRows: 200,
      ).then((data) => _filterFestivalsByMonth(data));
    });
  }

  void _resetFilters() {
    setState(() {
      selectedDate = generateDateOptions().first;
      selectedRegion = '';
      selectedCategory = '';
      currentPage = 1;
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        page: 1,
        numOfRows: 200,
      ).then((data) => _filterFestivalsByMonth(data));
    });
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const FestivalTopBar(currentTab: 'list'),
              const SizedBox(height: 12),
              FestivalFilterBar(
                selectedDate: selectedDate,
                selectedRegion: selectedRegion,
                selectedCategory: selectedCategory,
                onDateChanged: (val) {
                  setState(() => selectedDate = val);
                },
                onRegionChanged: (val) {
                  setState(() => selectedRegion = val);
                },
                onCategoryChanged: (val) {
                  setState(() => selectedCategory = val);
                },
                onSearchPressed: _fetchFiltered,
                onResetPressed: _resetFilters,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Festival>>(
                future: futureFestivals,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '에러: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  if (allFestivals.isEmpty) {
                    return const Center(
                      child: Text(
                        '축제가 없습니다.',
                        style: TextStyle(fontFamily: 'AstaSans'),
                      ),
                    );
                  }

                  final startIndex = (currentPage - 1) * itemsPerPage;
                  final endIndex = (startIndex + itemsPerPage < allFestivals.length)
                      ? startIndex + itemsPerPage
                      : allFestivals.length;
                  final currentPageItems = allFestivals.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      ...List.generate((currentPageItems.length / 2).ceil(), (index) {
                        final left = currentPageItems[index * 2];
                        final right = (index * 2 + 1 < currentPageItems.length)
                            ? currentPageItems[index * 2 + 1]
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: FestivalCard(festival: left)),
                              const SizedBox(width: 8),
                              if (right != null)
                                Expanded(child: FestivalCard(festival: right))
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentPage > 1)
                            TextButton(
                              onPressed: () => _goToPage(currentPage - 1),
                              child: const Text(
                                '이전',
                                style: TextStyle(fontFamily: 'AstaSans', fontSize: 14),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Text(
                            '페이지 $currentPage',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'AstaSans',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (endIndex < allFestivals.length)
                            TextButton(
                              onPressed: () => _goToPage(currentPage + 1),
                              child: const Text(
                                '다음',
                                style: TextStyle(fontFamily: 'AstaSans', fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}