import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:file_picker/file_picker.dart';
import 'dart:io';


class FrequencyChart extends StatefulWidget {
  final List<Grade>? grades;
  FrequencyChart({Key? key, this.grades}) : super(key: key);
  @override
  State<FrequencyChart> createState() => _FrequencyChartState();
}

class _FrequencyChartState extends State<FrequencyChart> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grades"),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          height: 500,
          child: charts.BarChart(
            generateChartData(),
            animate: true,
            vertical: false,
          ),
        ),
      ),
    );
  }


  List<charts.Series<Grade, String>> generateChartData() {
    // Sort grades by grade value in ascending order
    widget.grades!.sort((a, b) => a.grade!.compareTo(b.grade!));

    // Calculate frequency of each grade
    Map<String, int> frequencyMap = {};
    for (Grade grade in widget.grades!) {
      if (frequencyMap.containsKey(grade.grade)) {
        frequencyMap[grade.grade!] = frequencyMap[grade.grade!]! + 1;
      } else {
        frequencyMap[grade.grade!] = 1;
      }
    }

    // Convert the frequency map to a list of Grade objects
    List<Grade> frequencyData = [];
    frequencyMap.forEach((grade, frequency) {
      frequencyData.add(Grade(sid: grade, grade: frequency.toString(), id: null));
    });

    return [
      charts.Series<Grade, String>(
        id: 'Frequency',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (Grade grade, _) => grade.sid!,
        measureFn: (Grade grade, _) => int.parse(grade.grade!),
        data: frequencyData,
      ),
    ];
  }
}
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const ListGrades(),
    );
  }
  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode; // Toggle the value of isDarkMode
    });
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
  ListGradesState createState() => ListGradesState();
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
                initialValue: widget.grade?.sid,
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
                initialValue: widget.grade?.grade,
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
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    GradesModel.instance.update(Grade(
                      sid: _sid,
                      grade: _grade,
                      id: widget.grade?.id,
                    ));
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
class ListGradesState extends State<ListGrades> {
  int? _selectedIndex;
  List<Grade> _grades = [];
  bool _sortAscending = true;
  final TextEditingController _filter = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    refreshGrades();
    _filter.addListener(_searchListener);
  }

  void _searchListener() {
    setState(() {
      _searchText = _filter.text;
    });
  }

  Future refreshGrades() async {
    this._grades = await GradesModel.instance.readAllGrades();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Grade> filteredGrades = _grades.where((grade) {
      return grade.sid!.toLowerCase().contains(_searchText.toLowerCase()) ||
          grade.grade!.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Forms and SQLite'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              _showVerticalBarChart(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () {
              _importCSV(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.lightbulb),
            onPressed: () {
              _MyAppState parent = context.findAncestorStateOfType<_MyAppState>()!;
              parent.toggleDarkMode();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _filter,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGrades.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(filteredGrades[index].id.toString()),
                  onDismissed: (direction) {
                    _deleteGrade(filteredGrades[index].id!);
                  },
                  background: Container(
                    color: Colors.red,
                    child: Icon(Icons.delete),
                  ),
                  child: InkWell(
                    onLongPress: () {
                      _editGrade(filteredGrades[index]);
                    },
                    child: ListTile(
                      title: Text(filteredGrades[index].sid ?? ''),
                      subtitle: Text(filteredGrades[index].grade ?? ''),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

  void _importCSV(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      List<String> lines = await file.readAsLines();

      for (String line in lines) {
        List<String> values = line.split(',');

        if (values.length == 2) {
          String sid = values[0].trim();
          String grade = values[1].trim();

          // Check if the grade already exists in the list
          bool gradeExists = _grades.any((g) =>
          g.sid == sid && g.grade == grade);

          if (!gradeExists) {
            GradesModel.instance.create(
                Grade(sid: sid, grade: grade, id: null));
          }
        }
      }

      refreshGrades();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file imported successfully')),
      );
    }
  }
  void _deleteGrade(int id) {
    GradesModel.instance.delete(id);
    refreshGrades();
  }

  void _editGrade(Grade grade) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => GradeForm(grade: grade),
    )).then((_) {
      refreshGrades();
    });
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('Sort by Student ID'),
                onTap: () {
                  _sortGrades('sid');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('Sort by Grade'),
                onTap: () {
                  _sortGrades('grade');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortGrades(String sortBy) {
    setState(() {
      _sortAscending = !_sortAscending;
      _grades.sort((a, b) {
        switch (sortBy) {
          case 'sid':
            return _sortAscending ? a.sid!.compareTo(b.sid!) : b.sid!.compareTo(a.sid!);
          case 'grade':
            return _sortAscending ? a.grade!.compareTo(b.grade!) : b.grade!.compareTo(a.grade!);
          default:
            return 0;
        }
      });
    });
  }
  void _showVerticalBarChart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            height: 500,
            child: charts.BarChart(
              _generateVerticalBarChartData(_grades),
              animate: true,
            ),
          ),
        );
      },
    );
  }
}



List<charts.Series<Grade, String>> _generateVerticalBarChartData(List<Grade> grades) {
  // Sort grades by grade value
  grades.sort((a, b) => a.grade!.compareTo(b.grade!));

  // Calculate frequency of each grade
  Map<String, int> frequencyMap = {};
  for (Grade grade in grades) {
    if (frequencyMap.containsKey(grade.grade)) {
      frequencyMap[grade.grade!] = frequencyMap[grade.grade!]! + 1;
    } else {
      frequencyMap[grade.grade!] = 1;
    }
  }

  // Convert the frequency map to a list of Grade objects
  List<Grade> frequencyData = [];
  frequencyMap.forEach((grade, frequency) {
    frequencyData.add(Grade(sid: grade, grade: frequency.toString(), id: null));
  });

  return [
    charts.Series<Grade, String>(
      id: 'Frequency',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (Grade grade, _) => grade.sid!,
      measureFn: (Grade grade, _) => int.parse(grade.grade!),
      data: frequencyData,
    ),
  ];
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
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    GradesModel.instance.create(
                        Grade(sid: _sid, grade: _grade, id: null));
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
    final dbFilePath = path.join(dbPath, filePath);  // Use a different name, e.g., dbFilePath

    return await openDatabase(dbFilePath, version: 1, onCreate: _createDB);
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