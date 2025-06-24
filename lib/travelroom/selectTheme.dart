import 'package:flutter/material.dart';

import '../common/logo_header.dart';

class ThemeSelectPage extends StatefulWidget {
  @override
  _ThemeSelectPageState createState() => _ThemeSelectPageState();
}

class _ThemeSelectPageState extends State<ThemeSelectPage> {
  final List<String> themes = ['액티비티', '실내', '카페', '가족', '커플', '우정', '혼자', '맛집'];

  final Map<String, IconData> themeIcons = {
    '액티비티': Icons.directions_run,
    '실내': Icons.weekend,
    '카페': Icons.local_cafe,
    '가족': Icons.family_restroom,
    '커플': Icons.favorite,
    '우정': Icons.group,
    '혼자': Icons.person,
    '맛집': Icons.restaurant_menu,
  };

  List<String> selectedThemes = [];

  void _toggleTheme(String theme) {
    setState(() {
      if (selectedThemes.contains(theme)) {
        selectedThemes.remove(theme);
      } else {
        if (selectedThemes.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('최대 3개까지만 선택할 수 있어요')),
          );
          return;
        }
        selectedThemes.add(theme);
      }
    });
  }

  void _submitSelection() {
    Navigator.pop(context, selectedThemes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(
              child: const LogoHeader(bottomPadding: 0),
            ),
          ),
          // 상단 선택 뱃지
          if (selectedThemes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedThemes.map((theme) {
                  return Chip(
                    label: Text(
                      theme,
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                    deleteIcon: Icon(Icons.close, color: Colors.white),
                    onDeleted: () => _toggleTheme(theme),
                  );
                }).toList(),
              ),
            ),

          // 중간 Grid 박스
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 19, right: 19, top: 0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: themes.map((theme) {
                  final isSelected = selectedThemes.contains(theme);
                  final icon = themeIcons[theme] ?? Icons.category;

                  return GestureDetector(
                    onTap: () => _toggleTheme(theme),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.yellow[100] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.yellow : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 36,
                            color: isSelected ? Colors.blue[800] : Colors.black54,
                          ),
                          SizedBox(height: 8),
                          Text(
                            theme,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue[900] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ✅ 하단 완료 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selectedThemes.isEmpty ? null : _submitSelection,
              child: Text('선택 완료 (${selectedThemes.length}/3)'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
