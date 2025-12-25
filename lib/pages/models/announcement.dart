class Announcement {
  final int id;
  final String title;
  final String details;
  final String date;
  final String time;
  final String target;
  final int? barangayId;
  final String? targetRole; // ✅ Add this line
  final List<String> images;
  final String? createdAt;
    final String postedBy;

  Announcement({
    required this.id,
    required this.title,
    required this.details,
    required this.date,
    required this.time,
    required this.target,
    this.barangayId,
    this.targetRole, // ✅ Include in constructor
    required this.images,
    this.createdAt,
    required this.postedBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      target: json['target'] ?? '',
      barangayId: json['barangay_id'] != null
          ? int.tryParse(json['barangay_id'].toString())
          : null,
      targetRole: json['target_role'], // ✅ Parse this field
      images: (json['images'] as List?)?.map((img) {
            return img['path'].toString();
          }).toList() ?? [],
      createdAt: json['created_at'],
      postedBy: json['posted_by'] ?? '', 
    );
  }
}
