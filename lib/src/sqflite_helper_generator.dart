import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqflite_generator/sqlite_model.dart';

class SqfliteHelperGenerator extends GeneratorForAnnotation<SqliteModel> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@SqliteModel can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element as ClassElement;
    final className = classElement.displayName;
    final tableName = className.toLowerCase();

    final fields = classElement.fields.where((field) => !field.isStatic).toList();

    // Generate SQL fields
    final sqlFields = fields.map((field) {
      final type = _getSqliteType(field.type.getDisplayString());
      return '${field.name} $type';
    }).join(', ');
    
    final insertFields = fields.map((f) => "'${f.name}': instance.${f.name}").join(', ');

    // Generate CRUD helper methods
    return '''
    import 'package:sqflite/sqflite.dart';
    import '${element.source.uri}';

    class ${className}SqliteHelper {
      final Database db;

      ${className}SqliteHelper(this.db);

      Future<void> createTable() async {
        await db.execute(';
          CREATE TABLE $tableName (
            $sqlFields
          )'
        );
      }

      Future<int> insert$className($className instance) async {
        return await db.insert(
          '$tableName',
          {$insertFields},
        );
      }

      Future<$className?> get${className}ById(int id) async {
        final maps = await db.query(
          '$tableName',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (maps.isNotEmpty) {
          return $className(
            ${fields.map((f) => "${f.name}: maps[0]['${f.name}']").join(', ')}
          );
        }
        return null;
      }

      Future<List<$className>> getAll${className}s() async {
        final List<Map<String, dynamic>> maps = await db.query('$tableName');
        return List.generate(maps.length, (i) {
          return $className(
            ${fields.map((f) => "${f.name}: maps[i]['${f.name}']").join(', ')}
          );
        });
      }

      Future<int> update$className($className instance) async {
        return await db.update(
          '$tableName',
          {
            ${fields.map((f) => "'${f.name}': instance.${f.name}").join(', ')}
          },
          where: 'id = ?',
          whereArgs: [instance.id],
        );
      }

      Future<int> delete${className}ById(int id) async {
        return await db.delete(
          '$tableName',
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      Future<int> deleteAll${className}s() async {
        return await db.delete('$tableName');
      }
    }''';
  }

  String _getSqliteType(String dartType) {
    switch (dartType) {
      case 'int':
        return 'INTEGER';
      case 'String':
        return 'TEXT';
      case 'double':
        return 'REAL';
      default:
        return 'TEXT';
    }
  }
}
