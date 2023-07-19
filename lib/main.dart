import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await initializeDatabase();
  runApp(ReminderNoteApp(database));
}

Future<Database> initializeDatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), "reminders_notes.db"),
    onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE reminders(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, dateTime INTEGER)");
      await db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT)");
    },
    version: 1,
  );
}

class ReminderNoteApp extends StatelessWidget {
  final Database database;

  ReminderNoteApp(this.database);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder+Note App',
      theme: darkThemeData,
      debugShowCheckedModeBanner: false,
      home: ReminderNoteScreen(database),
    );
  }
}

final ThemeData darkThemeData = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    centerTitle: true,
    elevation: 0,
  ),
  textTheme: TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 16,
      color: Colors.white,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.red, // Change to red
  ),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red)
      .copyWith(secondary: Colors.orange),
);

class ReminderNoteScreen extends StatefulWidget {
  final Database database;

  ReminderNoteScreen(this.database);

  @override
  _ReminderNoteScreenState createState() => _ReminderNoteScreenState();
}

class _ReminderNoteScreenState extends State<ReminderNoteScreen> {
  List<Map<String, dynamic>> reminders = [];
  List<Map<String, dynamic>> notes = [];
  final TextEditingController _reminderController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _reminderFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final remindersList = await widget.database.query("reminders");
    final notesList = await widget.database.query("notes");

    setState(() {
      reminders = remindersList;
      notes = notesList;
    });
  }

  void _addReminder() async {
    if (_reminderController.text.isNotEmpty) {
      final reminder = {
        'title': _reminderController.text,
        'dateTime': DateTime.now().millisecondsSinceEpoch,
      };
      await widget.database.insert("reminders", reminder);

      setState(() {
        _reminderController.clear();
        _loadData();
      });
    }
  }

  void _addNote() async {
    if (_noteController.text.isNotEmpty) {
      final note = {
        'text': _noteController.text,
      };
      await widget.database.insert("notes", note);

      setState(() {
        _noteController.clear();
        _loadData();
      });
    }
  }

  void _deleteReminder(int id) async {
    await widget.database.delete("reminders", where: "id = ?", whereArgs: [id]);

    setState(() {
      _loadData();
    });
  }

  void _deleteNote(int id) async {
    await widget.database.delete("notes", where: "id = ?", whereArgs: [id]);

    setState(() {
      _loadData();
    });
  }

  Widget _buildElevatedBox(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800], // Replace this with your desired grayish color.
        borderRadius: BorderRadius.circular(10), // Adjust the border radius as needed.
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder+Notes'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                _buildAddButton(
                  _reminderController,
                  'Add Reminder',
                  Icons.add_alarm,
                  _addReminder,
                  _reminderFocus,
                ),
                SizedBox(height: 10),
                _buildAddButton(
                  _noteController,
                  'Add Note',
                  Icons.note_add,
                  _addNote,
                  _noteFocus,
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Reminders'),
                      Tab(text: 'Notes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            final dateTime =
                            DateTime.fromMillisecondsSinceEpoch(
                                reminder['dateTime']);
                            final formattedDateTime =
                            DateFormat.yMd().add_jm().format(dateTime);
                            return Dismissible(
                              key: ValueKey(reminder['id']),
                              background: Container(
                                color: Colors.white,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.red),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) =>
                                  _deleteReminder(reminder['id']),
                              child: _buildElevatedBox(
                                GestureDetector(
                                  onDoubleTap: () =>
                                      _editReminder(context, reminder),
                                  child: Card(
                                    elevation: 0, // Set to 0 to remove inner Card's elevation.
                                    child: ListTile(
                                      title: Text(reminder['title']),
                                      subtitle: Text(formattedDateTime),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return Dismissible(
                              key: ValueKey(note['id']),
                              background: Container(
                                color: Colors.white,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.red),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) =>
                                  _deleteNote(note['id']),
                              child: _buildElevatedBox(
                                GestureDetector(
                                  onDoubleTap: () => _editNote(context, note),
                                  child: Card(
                                    elevation: 0, // Set to 0 to remove inner Card's elevation.
                                    child: ListTile(
                                      title: Text(note['text']),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editReminder(BuildContext context, Map<String, dynamic> reminder) async {
    final newReminder = await showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        initialTitle: reminder['title'],
        initialDateTime: DateTime.fromMillisecondsSinceEpoch(
          reminder['dateTime'],
        ),
      ),
    );

    if (newReminder != null) {
      await widget.database.update(
        "reminders",
        {
          'title': newReminder['title'],
          'dateTime': newReminder['dateTime'].millisecondsSinceEpoch,
        },
        where: "id = ?",
        whereArgs: [reminder['id']],
      );

      setState(() {
        _loadData();
      });
    }
  }

  void _editNote(BuildContext context, Map<String, dynamic> note) async {
    final newNote = await showDialog(
      context: context,
      builder: (context) => _NoteDialog(initialText: note['text']),
    );

    if (newNote != null) {
      await widget.database.update(
        "notes",
        {'text': newNote},
        where: "id = ?",
        whereArgs: [note['id']],
      );

      setState(() {
        _loadData();
      });
    }
  }

  Widget _buildAddButton(TextEditingController controller, String label,
      IconData iconData, VoidCallback onPressed, FocusNode focusNode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[700],
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
              ),
              focusNode: focusNode,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, // Change to red
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(iconData, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final String initialTitle;
  final DateTime initialDateTime;

  _ReminderDialog({required this.initialTitle, required this.initialDateTime});

  @override
  _ReminderDialogState createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late TextEditingController _titleController;
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _dateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _dateTime,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null && pickedDate != _dateTime) {
                setState(() {
                  _dateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    _dateTime.hour,
                    _dateTime.minute,
                  );
                });
              }
            },
            child: Text('Pick Date'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_dateTime),
              );
              if (pickedTime != null) {
                setState(() {
                  _dateTime = DateTime(
                    _dateTime.year,
                    _dateTime.month,
                    _dateTime.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            },
            child: Text('Pick Time'),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'title': _titleController.text,
              'dateTime': _dateTime,
            });
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String initialText;

  _NoteDialog({required this.initialText});

  @override
  _NoteDialogState createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Note'),
      content: TextField(
        controller: _textController,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Note',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_textController.text);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
