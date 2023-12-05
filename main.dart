import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
        primaryColor: Colors.deepPurple,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Forms and Firestore'),
        ),
        body: ListGrades(),
      ),
    );
  }
}

class Grade {
  String? sid;
  String? grade;
  int? id;


  Grade({this.sid, this.grade, this.id});

  Map<String, dynamic> toMap() {
    return {
      'sid': sid,
      'grade': grade,
      'id': id,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      sid: map['sid'],
      grade: map['grade'],
      id: map['id'],
    );
  }
}

class ListGrades extends StatefulWidget {
  const ListGrades({Key? key}) : super(key: key);

  @override
  _ListGradesState createState() => _ListGradesState();
}

class GradeForm extends StatefulWidget {
  final Grade? grade;

  GradeForm({this.grade, Key? key}) : super(key: key);

  @override
  _GradeFormState createState() => _GradeFormState();
}

class _GradeFormState extends State<GradeForm> {
  final _formKey = GlobalKey<FormState>();
  String? _sid;
  String? _grade;

  @override
  void initState() {
    super.initState();

    if (widget.grade != null) {
      _sid = widget.grade!.sid;
      _grade = widget.grade!.grade;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Grade'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Student ID'),
                initialValue: _sid,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Student ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  _sid = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Grade'),
                initialValue: _grade,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Grade';
                  }
                  return null;
                },
                onSaved: (value) {
                  _grade = value;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final updatedGrade = Grade(sid: _sid, grade: _grade, id: widget.grade?.id);
                    GradesModel.instance.update(updatedGrade);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListGradesState extends State<ListGrades> {
  int? _selectedIndex; // Initialize with null
  List<Grade> _grades = [];

  @override
  void initState() {
    super.initState();
    refreshGrades();
  }

  Future refreshGrades() async {
    this._grades = await GradesModel.instance.readAllGrades();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _grades.length,
        itemBuilder: (context, index) {
          final sid = _grades[index].sid ?? ''; // Provide a default value
          final grade = _grades[index].grade ?? ''; // Provide a default value
          return Container(
            decoration: BoxDecoration(
              color: _selectedIndex == index ? Colors.blue : null,
            ),
            child: ListTile(
              title: Text(sid),
              subtitle: Text(grade),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => GradeForm(grade: _grades[index]),
                      ));
                      refreshGrades();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      final gradeId = _grades[index].id;
                      if (gradeId != null) {
                        _deleteGrade(gradeId);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddGradePage(),
          ));
          refreshGrades();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _deleteGrade(int id) {
    GradesModel.instance.delete(id);
    refreshGrades();
  }
}

class AddGradePage extends StatefulWidget {
  @override
  _AddGradePageState createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final _formKey = GlobalKey<FormState>();
  String? _sid;
  String? _grade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Grade'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Student ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Student ID';
                  }
                  return null;
                },
                onSaved: (value) {
                  _sid = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Grade'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Grade';
                  }
                  return null;
                },
                onSaved: (value) {
                  _grade = value;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    GradesModel.instance.create(Grade(sid: _sid, grade: _grade, id: null));
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradesModel {
  static final GradesModel instance = GradesModel._init();
  static Database? _database;

  GradesModel._init();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDB('grades.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE ${GradeFields.tableGrades} ( 
  ${GradeFields.id} $idType, 
  ${GradeFields.sid} $textType,
  ${GradeFields.grade} $textType
  )
''');
  }

  Future<Grade> create(Grade grade) async {
    final db = await database;
    final id = await db!.insert(GradeFields.tableGrades, grade.toMap());
    return grade..id = id;
  }

  Future<Grade> readGrade(int id) async {
    final db = await database;
    if (db == null) {
      throw Exception('Database is null');
    }

    final maps = await db.query(
      GradeFields.tableGrades,
      columns: GradeFields.values,
      where: '${GradeFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Grade.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Grade>> readAllGrades() async {
    final db = await database;
    final orderBy = '${GradeFields.id} ASC';
    final result = await db!.query(GradeFields.tableGrades, orderBy: orderBy);

    return result.map((json) => Grade.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    if (db == null) {
      throw Exception('Database is null');
    }

    return db.delete(
      GradeFields.tableGrades,
      where: '${GradeFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Grade grade) async {
    final db = await database;
    if (db == null) {
      throw Exception('Database is null');
    }

    return db.update(
      GradeFields.tableGrades,
      grade.toMap(),
      where: '${GradeFields.id} = ?',
      whereArgs: [grade.id],
    );
  }
}

class GradeFields {
  static final String tableGrades = 'grades';
  static final String id = 'id';
  static final String sid = 'sid';
  static final String grade = 'grade';

  static final List<String> values = [id, sid, grade];
}
