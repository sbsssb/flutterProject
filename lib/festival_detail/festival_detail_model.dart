class FestivalDetail {
  final String title;
  final String overview;
  final String address;
  final String tel;
  final String homepage;
  final double mapX;
  final double mapY;

  final String eventStartDate;
  final String eventEndDate;
  final String eventPlace;
  final String playTime;
  final String useTimeFestival;
  final String sponsor;
  final String bookingPlace;
  final String discountInfoFestival;

  final List<String> imageUrls;

  FestivalDetail({
    required this.title,
    required this.overview,
    required this.address,
    required this.tel,
    required this.homepage,
    required this.mapX,
    required this.mapY,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.eventPlace,
    required this.playTime,
    required this.useTimeFestival,
    required this.sponsor,
    required this.bookingPlace,
    required this.discountInfoFestival,
    required this.imageUrls,
  });
}