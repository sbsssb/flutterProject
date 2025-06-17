import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../utils/festival_top_bar.dart';
import 'festival_model.dart';
import 'festival_api.dart';
import 'festival_card.dart';

class FestivalCalendarPage extends StatefulWidget {
  const FestivalCalendarPage({super.key});

  @override
  State<FestivalCalendarPage> createState() => _FestivalCalendarPageState();
}

class _FestivalCalendarPageState extends State<FestivalCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, List<Festival>> festivalCache = {};
  final Map<DateTime, int> dailyFestivalCount = {};

  List<Festival> selectedDayFestivals = [];
  int currentPage = 1;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadFestivalDataIfNeeded(_focusedDay);
  }

  String _toYearMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _loadFestivalDataIfNeeded(DateTime targetDay) async {
    final key = _toYearMonthKey(targetDay);
    if (festivalCache.containsKey(key)) return;

    final start = DateFormat('yyyyMM01').format(targetDay);
    final end = DateFormat('yyyyMMdd').format(DateTime(targetDay.year, targetDay.month + 1, 0));

    final festivals = await fetchFestivals(
      eventStartDate: start,
      eventEndDate: end,
      numOfRows: 100,
    );

    final Map<DateTime, int> countMap = _countFestivalsPerDay(festivals);

    setState(() {
      festivalCache[key] = festivals;
      dailyFestivalCount.addAll(countMap);
    });

    _updateSelectedDayFestivals(_selectedDay ?? targetDay);
  }

  Map<DateTime, int> _countFestivalsPerDay(List<Festival> festivals) {
    final Map<DateTime, int> result = {};

    for (var fest in festivals) {
      final start = DateTime.parse(fest.eventStartDate);
      final end = DateTime.parse(fest.eventEndDate);

      for (var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))) {
        final date = DateTime(day.year, day.month, day.day);
        result[date] = (result[date] ?? 0) + 1;
      }
    }

    return result;
  }

  void _updateSelectedDayFestivals(DateTime selected) {
    final key = _toYearMonthKey(selected);
    final festivals = festivalCache[key] ?? [];

    final selectedList = festivals.where((festival) {
      final start = DateTime.parse(festival.eventStartDate);
      final end = DateTime.parse(festival.eventEndDate);
      return !selected.isBefore(start) && !selected.isAfter(end);
    }).toList();

    setState(() {
      selectedDayFestivals = selectedList;
      currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstAvailableDay = DateTime(today.year, today.month - 6, 1);
    final lastAvailableDay = DateTime(today.year, today.month + 7, 0);

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage < selectedDayFestivals.length)
        ? startIndex + itemsPerPage
        : selectedDayFestivals.length;
    final currentPageItems = selectedDayFestivals.sublist(startIndex, endIndex);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const FestivalTopBar(currentTab: 'calendar'),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: firstAvailableDay,
              lastDay: lastAvailableDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                final count = dailyFestivalCount[key] ?? 0;
                return List.filled(count, '축제');
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _updateSelectedDayFestivals(selected);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadFestivalDataIfNeeded(focusedDay);
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

            const SizedBox(height: 12),

            if (selectedDayFestivals.isEmpty)
              const Center(child: Text('해당 날짜에 축제가 없습니다.'))
            else ...[
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
                      onPressed: () {
                        setState(() {
                          currentPage--;
                        });
                      },
                      child: const Text('이전'),
                    ),
                  const SizedBox(width: 16),
                  Text('페이지 $currentPage'),
                  const SizedBox(width: 16),
                  if (endIndex < selectedDayFestivals.length)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentPage++;
                        });
                      },
                      child: const Text('다음'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ]
          ],
        ),
      ),
    );
  }
}