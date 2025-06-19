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

    Widget buildDropdown({
      required String iconPath,
      required String value,
      required List<DropdownMenuItem<String>> items,
      required void Function(String?) onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Image.asset(
                iconPath,
                width: 40,
                fit: BoxFit.contain,
            ),
            const SizedBox(width: 30),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          buildDropdown(
            iconPath: 'assets/festival_images/icons_calendar.png',
            value: selectedDate,
            items: dateOptions.map((date) => DropdownMenuItem(
              value: date,
              child: Text(
                '${date.substring(0, 4)}.${date.substring(4, 6)}',
                style: const TextStyle(
                  fontFamily: 'AstaSans',
                  fontSize: 22,
                ),
              ),
            )).toList(),
            onChanged: (value) => onDateChanged(value!),
          ),
          buildDropdown(
            iconPath: 'assets/festival_images/icons_address.png',
            value: selectedRegion,
            items: regionOptions.entries.map((e) => DropdownMenuItem(
              value: e.value,
              child: Text(
                  e.key,
                  style: const TextStyle(
                    fontFamily: 'AstaSans',
                    fontSize: 22,
                  ),
              ),
            )).toList(),
            onChanged: (value) => onRegionChanged(value!),
          ),
          buildDropdown(
            iconPath: 'assets/festival_images/icons_category.png',
            value: selectedCategory,
            items: categoryOptions.entries.map((entry) => DropdownMenuItem(
              value: entry.value,
              child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontFamily: 'AstaSans',
                    fontSize: 22,
                  ),
              ),
            )).toList(),
            onChanged: (value) => onCategoryChanged(value!),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 60,
                child: OutlinedButton(
                  onPressed: onResetPressed,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.grey),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/festival_images/icons_reset.png',
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 25),
                      const Text(
                        '초기화',
                        style: TextStyle(
                          fontFamily: 'AstaSans',
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 180,
                height: 60,
                child: ElevatedButton(
                  onPressed: onSearchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/festival_images/icons_search.png',
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 25),
                      const Text(
                        '검색',
                        style: TextStyle(
                          fontFamily: 'AstaSans',
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}