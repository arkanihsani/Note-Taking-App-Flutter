import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final CollectionReference notesRef =
      FirebaseFirestore.instance.collection("notes");

  Future<List<Note>> fetchNotes() async {
    final snapshot = await notesRef.orderBy("order").get();
    return snapshot.docs
        .map((doc) =>
            Note.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> addNote(String title, String content) async {
    final snapshot =
        await notesRef.orderBy("order", descending: true).limit(1).get();
    int nextOrder = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastOrder = snapshot.docs.first.get("order") ?? 0;
      nextOrder = lastOrder + 1;
    }
    await notesRef.add({
      "title": title,
      "content": content,
      "createdAt": FieldValue.serverTimestamp(),
      "order": nextOrder,
    });
  }

  Future<void> updateNote(String id, String title, String content) async {
    await notesRef.doc(id).update({
      "title": title,
      "content": content,
    });
  }

  Future<void> deleteNote(String id) async {
    await notesRef.doc(id).delete();
  }

  Future<void> updateNoteOrder(List<Note> notes) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < notes.length; i++) {
      final noteRef = notesRef.doc(notes[i].id);
      batch.update(noteRef, {"order": i});
    }
    await batch.commit();
  }
}
