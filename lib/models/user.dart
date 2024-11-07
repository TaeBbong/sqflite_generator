import 'package:sqflite_generator/sqlite_model.dart';

@SqliteModel()
class User {
  int? id;
  String? name;
  String? passwd;

  User({this.id, this.name, this.passwd});
}
