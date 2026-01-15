import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class DayEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get photoPath => text()();
  IntColumn get moodRating => integer()();
  TextColumn get note => text().nullable()();
  // ✅ Coloanele noi:
  TextColumn get location => text().nullable()();
  TextColumn get weatherTemp => text().nullable()();
  TextColumn get weatherIcon => text().nullable()();
}

@DriftDatabase(tables: [DayEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // ✅ Incrementat de la 1 la 2

  // ✅ Adăugăm logica de migrare (ca să nu pierzi pozele vechi)
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Adaugă coloanele noi la tabelul existent
          await m.addColumn(dayEntries, dayEntries.location);
          await m.addColumn(dayEntries, dayEntries.weatherTemp);
          await m.addColumn(dayEntries, dayEntries.weatherIcon);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'krono_database');
  }
}