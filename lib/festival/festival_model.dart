class Festival {
  final String contentId;
  final int contentTypeId;
  final String title;
  final String imageUrl;
  final String address;
  final String tel;
  final double mapX;
  final double mapY;
  final String areaCode;
  final String sigunguCode;
  final String cat1;
  final String cat2;
  final String cat3;
  final String eventStartDate;
  final String eventEndDate;

  Festival({
    required this.contentId,
    required this.contentTypeId,
    required this.title,
    required this.imageUrl,
    required this.address,
    required this.tel,
    required this.mapX,
    required this.mapY,
    required this.areaCode,
    required this.sigunguCode,
    required this.cat1,
    required this.cat2,
    required this.cat3,
    required this.eventStartDate,
    required this.eventEndDate,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      contentId: json['contentid'].toString(),
      contentTypeId: int.tryParse(json['contenttypeid'] ?? '') ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['firstimage'] ?? '',
      address: '${json['addr1'] ?? ''} ${json['addr2'] ?? ''}'.trim(),
      tel: json['tel'] ?? '',
      mapX: double.tryParse(json['mapx']?.toString() ?? '0') ?? 0.0,
      mapY: double.tryParse(json['mapy']?.toString() ?? '0') ?? 0.0,
      areaCode: json['areacode']?.toString() ?? '',
      sigunguCode: json['sigungucode']?.toString() ?? '',
      cat1: json['cat1'] ?? '',
      cat2: json['cat2'] ?? '',
      cat3: json['cat3'] ?? '',
      eventStartDate: json['eventstartdate'] ?? '',
      eventEndDate: json['eventenddate'] ?? '',
    );
  }
}