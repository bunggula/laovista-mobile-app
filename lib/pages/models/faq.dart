class Faq {
  final int id;
  final String question;
  final String answer;
  final String? category;

  Faq({required this.id, required this.question, required this.answer, this.category});

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
    id: json['id'],
    question: json['question'],
    answer: json['answer'],
    category: json['category'],
  );
}
