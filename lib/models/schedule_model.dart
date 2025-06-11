class Schedule {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String placeName;
  bool isDone;
  bool canStamp;
  bool canStampAlreadyNoti = false;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.placeName,
    required this.isDone,
    this.canStamp = false,
});

  factory Schedule.fromMap(Map<String,dynamic> map, String id){
    return Schedule(
        id: id,
        title: map['travel_title']?? '',
        description: map['description']?? '',
        lat: map['lat']?? 0.0,
        lng: map['lng']?? 0.0,
        placeName: map['place_name']?? '',
        isDone: map['is_done']?? false,
    );
  }

}