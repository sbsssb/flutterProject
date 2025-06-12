import 'package:flutter/material.dart';
import 'package:flutterteam4/utils/festival_options.dart';

class FestivalFilterBar extends StatelessWidget {
  final String selectedDate;
  final String selectedRegion;
  final String selectedCategory;
  final void Function(String) onDateChanged;
  final void Function(String) onRegionChanged;
  final void Function(String) onCategoryChanged;
  final VoidCallback onSearchPressed;
  final VoidCallback onResetPressed;

  const FestivalFilterBar({
    super.key,
    required this.selectedDate,
    required this.selectedRegion,
    required this.selectedCategory,
    required this.onDateChanged,
    required this.onRegionChanged,
    required this.onCategoryChanged,
    required this.onSearchPressed,
    required this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dateOptions = generateDateOptions();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          DropdownButton<String>(
            value: selectedDate,
            onChanged: (value) => onDateChanged(value!),
            items: dateOptions.map((date) {
              return DropdownMenuItem(
                value: date,
                child: Text('${date.substring(0, 4)}.${date.substring(4, 6)}'),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            value: selectedRegion,
            onChanged: (value) => onRegionChanged(value!),
            items: regionOptions.entries.map((e) {
              return DropdownMenuItem(
                value: e.value,
                child: Text(e.key),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            value: themeOptions.contains(selectedCategory)
                ? selectedCategory
                : themeOptions.first,
            onChanged: (value) => onCategoryChanged(value!),
            items: themeOptions.map((theme) {
              return DropdownMenuItem(
                value: theme,
                child: Text(theme),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onResetPressed,
                icon: const Icon(Icons.refresh),
                label: const Text('초기화'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onSearchPressed,
                icon: const Icon(Icons.search),
                label: const Text('검색'),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}
