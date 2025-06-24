import 'package:flutter/material.dart';

import '../common/logo_header.dart';

class RegionSelectPage extends StatelessWidget {
  const RegionSelectPage({Key? key}) : super(key: key);

  // 지도에 오버레이할 지역 목록 (좌표는 지도 이미지 기준 수작업 조정 필요)
  final List<Map<String, dynamic>> regions = const [
    {'label': '서울', 'value': '서울특별시', 'left': 90.0, 'top': 115.0},
    {'label': '경기', 'value': '경기도', 'left': 120.0, 'top': 140.0},
    {'label': '강원', 'value': '강원도', 'left': 210.0, 'top': 90.0},
    {'label': '인천', 'value': '인천광역시', 'left': 55.0, 'top': 105.0},
    {'label': '충북', 'value': '충청북도', 'left': 160.0, 'top': 190.0},
    {'label': '충남', 'value': '충청남도', 'left': 80.0, 'top': 210.0},
    {'label': '세종', 'value': '세종시', 'left': 120.0, 'top': 215.0},
    {'label': '대전', 'value': '대전광역시', 'left': 125.0, 'top': 250.0},
    {'label': '전북', 'value': '전라북도', 'left': 110.0, 'top': 300.0},
    {'label': '전남', 'value': '전라남도', 'left': 80.0, 'top': 400.0},
    {'label': '광주', 'value': '광주광역시', 'left': 77.0, 'top': 365.0},
    {'label': '경북', 'value': '경상북도', 'left': 240.0, 'top': 240.0},
    {'label': '경남', 'value': '경상남도', 'left': 210.0, 'top': 340.0},
    {'label': '부산', 'value': '부산광역시', 'left': 290.0, 'top': 360.0},
    {'label': '울산', 'value': '울산광역시', 'left': 298.0, 'top': 328.0},
    {'label': '대구', 'value': '대구광역시', 'left': 230.0, 'top': 290.0},
    {'label': '제주', 'value': '제주도', 'left': 50.0, 'top': 545.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ⬆️ 로고
            Padding(
              padding: const EdgeInsets.all(0),
              child: const LogoHeader(bottomPadding: 0),
            ),

            // ⬇️ 지도 + 버튼 영역
            Expanded(
              child: Center(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/travel_images/map2.png',
                      width: 400,
                      height: 600,
                      fit: BoxFit.cover,
                    ),
                    ...regions.map((region) {
                      return Positioned(
                        left: region['left'],
                        top: region['top'],
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context, region['value']);
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            alignment: Alignment.center,
                            color: Colors.transparent,
                            child: Text(
                              region['label'],
                              style: TextStyle(
                                fontFamily: 'Jalnan',
                                fontSize: 19,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
