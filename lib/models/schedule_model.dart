class Schedule {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String placeName;
  final bool isDone;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.placeName,
    required this.isDone,
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