class Format {
  final int id;
  final String title;
  final String content;

  Format({required this.id, required this.title, required this.content});

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }
}
