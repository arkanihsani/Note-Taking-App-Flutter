import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NotesPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const NotesPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService _service = NoteService();
  List<Note> _notes = [];
  bool _confirmDeleteEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _service.fetchNotes();
    notes.sort((a, b) => a.order.compareTo(b.order));
    setState(() => _notes = notes);
  }

  void _showAddDialog() {
    String title = "";
    String content = "";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (val) => title = val, decoration: const InputDecoration(labelText: "Title")),
            TextField(onChanged: (val) => content = val, decoration: const InputDecoration(labelText: "Content")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (title.trim().isEmpty) return;
              await _service.addNote(title, content);
              Navigator.pop(context);
              _loadNotes();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _showEditDialog(Note note) {
    String title = note.title;
    String content = note.content ?? "";
    final titleController = TextEditingController(text: title);
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, onChanged: (val) => title = val, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: contentController, onChanged: (val) => content = val, decoration: const InputDecoration(labelText: "Content")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _service.updateNote(note.id, title, content);
              Navigator.pop(context);
              _loadNotes();
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  void _deleteNote(Note note) async {
    if (_confirmDeleteEnabled) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Note"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
          ],
        ),
      );
      if (shouldDelete == true) {
        await _service.deleteNote(note.id);
        _loadNotes();
      }
    } else {
      await _service.deleteNote(note.id);
      _loadNotes();
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Settings"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: _confirmDeleteEnabled,
                    title: const Text("Confirm before deleting"),
                    onChanged: (val) {
                      setStateDialog(() {
                        _confirmDeleteEnabled = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    value: widget.isDarkMode,
                    title: const Text("Dark Mode"),
                    onChanged: (val) {
                      widget.onThemeChanged(val);
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final note = _notes.removeAt(oldIndex);
      _notes.insert(newIndex, note);
    });
    await _service.updateNoteOrder(_notes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings)],
      ),
      body: _notes.isEmpty
          ? const Center(child: Text("No notes yet"))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _notes.length,
              onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
              itemBuilder: (context, i) {
                final note = _notes[i];
                return Container(
                  key: ValueKey(note.id),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Material(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showEditDialog(note),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (note.content != null && note.content!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        note.content!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}
