class Event {
  final int id;
  final int barangayId;
  final String title;
  final String date;
  final String time;
  final String venue;
  final String details;
  final String status;
  final String postedBy;
  final List<String> images;
  final String? updatedDate; // NEW: to track approval date

  Event({
    required this.id,
    required this.barangayId,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.details,
    required this.status,
    required this.postedBy,
    required this.images,
    this.updatedDate, // optional
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    print("📦 Raw event JSON: $json"); // DEBUG LOG

    return Event(
      id: json['id'],
      barangayId: json['barangay_id'] ?? 0,
      title: json['title'],
      date: json['date'],
      time: json['time'],
      venue: json['venue'],
      details: json['details'],
      status: json['status'],
      postedBy: json['posted_by'] ?? 'N/A',
      images: (json['images'] as List)
          .map((img) => img['path'] as String)
          .toList(),
      updatedDate: json['updated_date'], // use the DB field for approval
    );
  }
}
