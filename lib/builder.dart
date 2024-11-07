import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/sqflite_helper_generator.dart';
import 'package:sqflite_generator/sqlite_model.dart';

Builder sqliteHelperBuilder(BuilderOptions options) => 
    LibraryBuilder(SqfliteHelperGenerator(), generatedExtension: '.sqlite_helper.dart');
