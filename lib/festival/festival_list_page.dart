import 'package:flutter/material.dart';
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
  final int numOfRows = 10;
  bool isLastPage = false;

  late Future<List<Festival>> futureFestivals;

  @override
  void initState() {
    super.initState();
    selectedDate = generateDateOptions().first;
    futureFestivals = fetchFestivals(
      eventStartDate: selectedDate,
      page: currentPage,
      numOfRows: numOfRows,
    );
  }

  void _fetchFiltered() {
    setState(() {
      currentPage = 1;
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        areaCode: selectedRegion,
        cat3: selectedCategory,
        page: currentPage,
        numOfRows: numOfRows,
      ).then((data) {
        setState(() {
          isLastPage = data.length < numOfRows;
        });
        return data;
      });
    });
    print('🎯 검색: date=$selectedDate, region=$selectedRegion, cat3=${selectedCategory == '전체' ? '' : selectedCategory}');
  }

  void _resetFilters() {
    setState(() {
      selectedDate = generateDateOptions().first;
      selectedRegion = '';
      selectedCategory = '';
      currentPage = 1;
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        page: currentPage,
        numOfRows: numOfRows,
      );
    });
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        areaCode: selectedRegion,
        cat3: selectedCategory,
        page: currentPage,
        numOfRows: numOfRows,
      ).then((data) {
        setState(() {
          isLastPage = data.length < numOfRows;
        });
        return data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('축제 리스트')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
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
                    return Center(child: Text('에러: ${snapshot.error}'));
                  }

                  final festivals = snapshot.data ?? [];

                  if (festivals.isEmpty) {
                    return const Center(child: Text('축제가 없습니다.'));
                  }

                  return Column(
                    children: [
                      ...List.generate((festivals.length / 2).ceil(), (index) {
                        final left = festivals[index * 2];
                        final right = (index * 2 + 1 < festivals.length)
                            ? festivals[index * 2 + 1]
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
                              child: const Text('이전'),
                            ),
                          const SizedBox(width: 16),
                          Text('페이지 $currentPage'),
                          const SizedBox(width: 16),
                          if (festivals.length == numOfRows)
                            TextButton(
                              onPressed: () => _goToPage(currentPage + 1),
                              child: const Text('다음'),
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