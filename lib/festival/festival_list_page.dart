import 'package:flutter/material.dart';
import 'festival_api.dart';
import 'festival_model.dart';
import 'festival_card.dart';
import 'festival_filter_bar.dart';
import 'package:flutterteam4/utils/festival_options.dart';

class FestivalListPage extends StatefulWidget {
  const FestivalListPage({super.key});

  @override
  State<FestivalListPage> createState() => _FestivalListPageState();
}

class _FestivalListPageState extends State<FestivalListPage> {
  late String selectedDate;
  String selectedRegion = '';
  String selectedCategory = '전체';
  String filteredTheme = '전체';

  late Future<List<Festival>> futureFestivals;

  @override
  void initState() {
    super.initState();
    selectedDate = generateDateOptions().first;
    futureFestivals = fetchFestivals(eventStartDate: selectedDate);
  }

  void _fetchFiltered() {
    setState(() {
      futureFestivals = fetchFestivals(
        eventStartDate: selectedDate,
        areaCode: selectedRegion,
      );
      filteredTheme = selectedCategory;
    });
  }

  void _resetFilters() {
    setState(() {
      selectedDate = generateDateOptions().first;
      selectedRegion = '';
      selectedCategory = '전체';
      filteredTheme = '전체';
      futureFestivals = fetchFestivals(eventStartDate: selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('축제 리스트')),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: FestivalFilterBar(
              selectedDate: selectedDate,
              selectedRegion: selectedRegion,
              selectedCategory: selectedCategory,
              onDateChanged: (val) => setState(() => selectedDate = val),
              onRegionChanged: (val) => setState(() => selectedRegion = val),
              onCategoryChanged: (val) => setState(() => selectedCategory = val),
              onSearchPressed: _fetchFiltered,
              onResetPressed: _resetFilters,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Festival>>(
              future: futureFestivals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('에러: ${snapshot.error}'));
                }

                final festivals = filterFestivalsByTheme(
                  snapshot.data ?? [],
                  filteredTheme,
                );

                if (festivals.isEmpty) {
                  return const Center(child: Text('축제가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: (festivals.length / 2).ceil(),
                  itemBuilder: (context, index) {
                    final left = festivals[index * 2];
                    final right = (index * 2 + 1 < festivals.length)
                        ? festivals[index * 2 + 1]
                        : null;

                    return Row(
                      children: [
                        Expanded(child: FestivalCard(festival: left)),
                        if (right != null)
                          Expanded(child: FestivalCard(festival: right)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}