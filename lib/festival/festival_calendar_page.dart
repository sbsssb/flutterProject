import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../common/bottom_nav_bar.dart';
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
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const FestivalTopBar(currentTab: 'calendar'),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: SizedBox(
                height: 520,
                child: TableCalendar(
                  availableGestures: AvailableGestures.none,
                  locale: 'ko_KR',
                  firstDay: firstAvailableDay,
                  lastDay: lastAvailableDay,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  rowHeight: 70,
                  daysOfWeekHeight: 35,
                  daysOfWeekVisible: true,
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.E('ko_KR').format(day);
                      final isSunday = day.weekday == DateTime.sunday;
                      final isSaturday = day.weekday == DateTime.saturday;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontFamily: 'AstaSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isSunday
                                  ? Colors.redAccent
                                  : isSaturday
                                  ? Colors.blueAccent
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, _) {
                      final count = dailyFestivalCount[DateTime(date.year, date.month, date.day)] ?? 0;
                      final isToday = isSameDay(date, DateTime.now());
                      final isSelected = isSameDay(date, _selectedDay);

                      Color? bgColor;
                      Color textColor = Colors.black;

                      if (isSelected) {
                        bgColor = Colors.blue;
                        textColor = Colors.white;
                      } else if (isToday) {
                        bgColor = Colors.black;
                        textColor = Colors.white;
                      }

                      return Container(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontFamily: 'AstaSans',
                                  color: textColor,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (count > 0) ...[
                              Text(
                                  '$count개',
                                  style: const TextStyle(
                                      fontFamily: 'AstaSans',
                                      fontSize: 12,
                                      color: Colors.grey,
                                  ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 12, color: Colors.grey),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                        fontFamily: 'AstaSans',
                        color: Colors.white,
                        fontSize: 18
                    ),
                    todayTextStyle: TextStyle(
                        fontFamily: 'AstaSans',
                        color: Colors.white,
                        fontSize: 18
                    ),
                    defaultTextStyle: TextStyle(
                        fontFamily: 'AstaSans',
                        fontSize: 14
                    ),
                    weekendTextStyle: TextStyle(
                        fontFamily: 'AstaSans',
                        fontSize: 14,
                        color: Colors.redAccent
                    ),
                    cellMargin: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onDaySelected: (selected, _) {
                    setState(() {
                      _selectedDay = selected;
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
                      child: Text(
                          '이전',
                          style: TextStyle(
                            fontFamily: 'AstaSans',
                            fontSize: 14,
                          ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Text(''
                      '페이지 $currentPage',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'AstaSans',
                        fontSize: 14,
                      ),
                  ),
                  const SizedBox(width: 16),
                  if (endIndex < selectedDayFestivals.length)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentPage++;
                        });
                      },
                      child: Text(
                          '다음',
                          style: TextStyle(
                          fontFamily: 'AstaSans',
                          fontSize: 14,
                          ),
                      ),
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