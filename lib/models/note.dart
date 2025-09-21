import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
  final int order;

  Note({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
    required this.order,
  });

  factory Note.fromFirestore(Map<String, dynamic> json, String id) {
    return Note(
      id: id,
      title: json["title"],
      content: json["content"],
      createdAt: (json["createdAt"] as Timestamp).toDate(),
      order: json["order"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "content": content,
      "createdAt": createdAt,
      "order": order,
    };
  }
}
