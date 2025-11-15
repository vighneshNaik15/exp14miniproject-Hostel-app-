class HolidayModel {
  final String name;
  final String date;
  final bool public;

  HolidayModel({
    required this.name,
    required this.date,
    required this.public,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      name: json["name"] ?? "No Name",
      date: json["date"] ?? "Unknown",
      public: json["public"] ?? false,
    );
  }
}
