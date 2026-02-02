// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DayEntriesTable extends DayEntries
    with TableInfo<$DayEntriesTable, DayEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _moodRatingMeta =
      const VerificationMeta('moodRating');
  @override
  late final GeneratedColumn<int> moodRating = GeneratedColumn<int>(
      'mood_rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weatherTempMeta =
      const VerificationMeta('weatherTemp');
  @override
  late final GeneratedColumn<String> weatherTemp = GeneratedColumn<String>(
      'weather_temp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weatherIconMeta =
      const VerificationMeta('weatherIcon');
  @override
  late final GeneratedColumn<String> weatherIcon = GeneratedColumn<String>(
      'weather_icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        photoPath,
        thumbnailPath,
        moodRating,
        note,
        location,
        weatherTemp,
        weatherIcon
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DayEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('mood_rating')) {
      context.handle(
          _moodRatingMeta,
          moodRating.isAcceptableOrUnknown(
              data['mood_rating']!, _moodRatingMeta));
    } else if (isInserting) {
      context.missing(_moodRatingMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('weather_temp')) {
      context.handle(
          _weatherTempMeta,
          weatherTemp.isAcceptableOrUnknown(
              data['weather_temp']!, _weatherTempMeta));
    }
    if (data.containsKey('weather_icon')) {
      context.handle(
          _weatherIconMeta,
          weatherIcon.isAcceptableOrUnknown(
              data['weather_icon']!, _weatherIconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      moodRating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_rating'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      weatherTemp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weather_temp']),
      weatherIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weather_icon']),
    );
  }

  @override
  $DayEntriesTable createAlias(String alias) {
    return $DayEntriesTable(attachedDatabase, alias);
  }
}

class DayEntry extends DataClass implements Insertable<DayEntry> {
  /// Unique identifier for each entry.
  final int id;

  /// The timestamp when the entry was captured.
  final DateTime date;

  /// Local file system path to the captured image.
  final String photoPath;

  /// Local file system path to the generated thumbnail.
  final String? thumbnailPath;

  /// User's mood rating (typically on a scale of 1-5).
  final int moodRating;

  /// Optional text content provided by the user.
  final String? note;

  /// Formatted address or city name where the entry was created.
  final String? location;

  /// Temperature at the time of entry (e.g., "22°C").
  final String? weatherTemp;

  /// Identifier or URL for the weather condition icon.
  final String? weatherIcon;
  const DayEntry(
      {required this.id,
      required this.date,
      required this.photoPath,
      this.thumbnailPath,
      required this.moodRating,
      this.note,
      this.location,
      this.weatherTemp,
      this.weatherIcon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['mood_rating'] = Variable<int>(moodRating);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || weatherTemp != null) {
      map['weather_temp'] = Variable<String>(weatherTemp);
    }
    if (!nullToAbsent || weatherIcon != null) {
      map['weather_icon'] = Variable<String>(weatherIcon);
    }
    return map;
  }

  DayEntriesCompanion toCompanion(bool nullToAbsent) {
    return DayEntriesCompanion(
      id: Value(id),
      date: Value(date),
      photoPath: Value(photoPath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      moodRating: Value(moodRating),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      weatherTemp: weatherTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherTemp),
      weatherIcon: weatherIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherIcon),
    );
  }

  factory DayEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      moodRating: serializer.fromJson<int>(json['moodRating']),
      note: serializer.fromJson<String?>(json['note']),
      location: serializer.fromJson<String?>(json['location']),
      weatherTemp: serializer.fromJson<String?>(json['weatherTemp']),
      weatherIcon: serializer.fromJson<String?>(json['weatherIcon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'photoPath': serializer.toJson<String>(photoPath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'moodRating': serializer.toJson<int>(moodRating),
      'note': serializer.toJson<String?>(note),
      'location': serializer.toJson<String?>(location),
      'weatherTemp': serializer.toJson<String?>(weatherTemp),
      'weatherIcon': serializer.toJson<String?>(weatherIcon),
    };
  }

  DayEntry copyWith(
          {int? id,
          DateTime? date,
          String? photoPath,
          Value<String?> thumbnailPath = const Value.absent(),
          int? moodRating,
          Value<String?> note = const Value.absent(),
          Value<String?> location = const Value.absent(),
          Value<String?> weatherTemp = const Value.absent(),
          Value<String?> weatherIcon = const Value.absent()}) =>
      DayEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        photoPath: photoPath ?? this.photoPath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        moodRating: moodRating ?? this.moodRating,
        note: note.present ? note.value : this.note,
        location: location.present ? location.value : this.location,
        weatherTemp: weatherTemp.present ? weatherTemp.value : this.weatherTemp,
        weatherIcon: weatherIcon.present ? weatherIcon.value : this.weatherIcon,
      );
  DayEntry copyWithCompanion(DayEntriesCompanion data) {
    return DayEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      moodRating:
          data.moodRating.present ? data.moodRating.value : this.moodRating,
      note: data.note.present ? data.note.value : this.note,
      location: data.location.present ? data.location.value : this.location,
      weatherTemp:
          data.weatherTemp.present ? data.weatherTemp.value : this.weatherTemp,
      weatherIcon:
          data.weatherIcon.present ? data.weatherIcon.value : this.weatherIcon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('moodRating: $moodRating, ')
          ..write('note: $note, ')
          ..write('location: $location, ')
          ..write('weatherTemp: $weatherTemp, ')
          ..write('weatherIcon: $weatherIcon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, photoPath, thumbnailPath,
      moodRating, note, location, weatherTemp, weatherIcon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.photoPath == this.photoPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.moodRating == this.moodRating &&
          other.note == this.note &&
          other.location == this.location &&
          other.weatherTemp == this.weatherTemp &&
          other.weatherIcon == this.weatherIcon);
}

class DayEntriesCompanion extends UpdateCompanion<DayEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> photoPath;
  final Value<String?> thumbnailPath;
  final Value<int> moodRating;
  final Value<String?> note;
  final Value<String?> location;
  final Value<String?> weatherTemp;
  final Value<String?> weatherIcon;
  const DayEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.moodRating = const Value.absent(),
    this.note = const Value.absent(),
    this.location = const Value.absent(),
    this.weatherTemp = const Value.absent(),
    this.weatherIcon = const Value.absent(),
  });
  DayEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String photoPath,
    this.thumbnailPath = const Value.absent(),
    required int moodRating,
    this.note = const Value.absent(),
    this.location = const Value.absent(),
    this.weatherTemp = const Value.absent(),
    this.weatherIcon = const Value.absent(),
  })  : date = Value(date),
        photoPath = Value(photoPath),
        moodRating = Value(moodRating);
  static Insertable<DayEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? photoPath,
    Expression<String>? thumbnailPath,
    Expression<int>? moodRating,
    Expression<String>? note,
    Expression<String>? location,
    Expression<String>? weatherTemp,
    Expression<String>? weatherIcon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (photoPath != null) 'photo_path': photoPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (moodRating != null) 'mood_rating': moodRating,
      if (note != null) 'note': note,
      if (location != null) 'location': location,
      if (weatherTemp != null) 'weather_temp': weatherTemp,
      if (weatherIcon != null) 'weather_icon': weatherIcon,
    });
  }

  DayEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? photoPath,
      Value<String?>? thumbnailPath,
      Value<int>? moodRating,
      Value<String?>? note,
      Value<String?>? location,
      Value<String?>? weatherTemp,
      Value<String?>? weatherIcon}) {
    return DayEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      moodRating: moodRating ?? this.moodRating,
      note: note ?? this.note,
      location: location ?? this.location,
      weatherTemp: weatherTemp ?? this.weatherTemp,
      weatherIcon: weatherIcon ?? this.weatherIcon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (moodRating.present) {
      map['mood_rating'] = Variable<int>(moodRating.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (weatherTemp.present) {
      map['weather_temp'] = Variable<String>(weatherTemp.value);
    }
    if (weatherIcon.present) {
      map['weather_icon'] = Variable<String>(weatherIcon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('moodRating: $moodRating, ')
          ..write('note: $note, ')
          ..write('location: $location, ')
          ..write('weatherTemp: $weatherTemp, ')
          ..write('weatherIcon: $weatherIcon')
          ..write(')'))
        .toString();
  }
}

class $StreakAdjustmentsTable extends StreakAdjustments
    with TableInfo<$StreakAdjustmentsTable, StreakAdjustment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakAdjustmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  late final GeneratedColumnWithTypeConverter<StreakAdjustmentType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<StreakAdjustmentType>(
              $StreakAdjustmentsTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [id, date, createdAt, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_adjustments';
  @override
  VerificationContext validateIntegrity(Insertable<StreakAdjustment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakAdjustment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakAdjustment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      type: $StreakAdjustmentsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
    );
  }

  @override
  $StreakAdjustmentsTable createAlias(String alias) {
    return $StreakAdjustmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StreakAdjustmentType, int, int> $convertertype =
      const EnumIndexConverter<StreakAdjustmentType>(
          StreakAdjustmentType.values);
}

class StreakAdjustment extends DataClass
    implements Insertable<StreakAdjustment> {
  final int id;

  /// The specific date being "bridged" or "frozen".
  final DateTime date;
  final DateTime createdAt;

  /// Type of adjustment: 'freeze' (grace period) or 'restore' (paid).
  final StreakAdjustmentType type;
  const StreakAdjustment(
      {required this.id,
      required this.date,
      required this.createdAt,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['type'] =
          Variable<int>($StreakAdjustmentsTable.$convertertype.toSql(type));
    }
    return map;
  }

  StreakAdjustmentsCompanion toCompanion(bool nullToAbsent) {
    return StreakAdjustmentsCompanion(
      id: Value(id),
      date: Value(date),
      createdAt: Value(createdAt),
      type: Value(type),
    );
  }

  factory StreakAdjustment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakAdjustment(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: $StreakAdjustmentsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer
          .toJson<int>($StreakAdjustmentsTable.$convertertype.toJson(type)),
    };
  }

  StreakAdjustment copyWith(
          {int? id,
          DateTime? date,
          DateTime? createdAt,
          StreakAdjustmentType? type}) =>
      StreakAdjustment(
        id: id ?? this.id,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        type: type ?? this.type,
      );
  StreakAdjustment copyWithCompanion(StreakAdjustmentsCompanion data) {
    return StreakAdjustment(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakAdjustment(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, createdAt, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakAdjustment &&
          other.id == this.id &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.type == this.type);
}

class StreakAdjustmentsCompanion extends UpdateCompanion<StreakAdjustment> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<StreakAdjustmentType> type;
  const StreakAdjustmentsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
  });
  StreakAdjustmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.createdAt = const Value.absent(),
    required StreakAdjustmentType type,
  })  : date = Value(date),
        type = Value(type);
  static Insertable<StreakAdjustment> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<int>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
    });
  }

  StreakAdjustmentsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<DateTime>? createdAt,
      Value<StreakAdjustmentType>? type}) {
    return StreakAdjustmentsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $StreakAdjustmentsTable.$convertertype.toSql(type.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakAdjustmentsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $ActivityLogTable extends ActivityLog
    with TableInfo<$ActivityLogTable, ActivityLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_log';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $ActivityLogTable createAlias(String alias) {
    return $ActivityLogTable(attachedDatabase, alias);
  }
}

class ActivityLogData extends DataClass implements Insertable<ActivityLogData> {
  /// The unique identifier for the log entry.
  final int id;

  /// The calendar date of the completed activity.
  ///
  /// This column has a unique constraint to ensure each date is logged only once.
  /// The time component of the [DateTime] should be ignored.
  final DateTime date;
  const ActivityLogData({required this.id, required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  ActivityLogCompanion toCompanion(bool nullToAbsent) {
    return ActivityLogCompanion(
      id: Value(id),
      date: Value(date),
    );
  }

  factory ActivityLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityLogData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  ActivityLogData copyWith({int? id, DateTime? date}) => ActivityLogData(
        id: id ?? this.id,
        date: date ?? this.date,
      );
  ActivityLogData copyWithCompanion(ActivityLogCompanion data) {
    return ActivityLogData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLogData(')
          ..write('id: $id, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityLogData &&
          other.id == this.id &&
          other.date == this.date);
}

class ActivityLogCompanion extends UpdateCompanion<ActivityLogData> {
  final Value<int> id;
  final Value<DateTime> date;
  const ActivityLogCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
  });
  ActivityLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
  }) : date = Value(date);
  static Insertable<ActivityLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
    });
  }

  ActivityLogCompanion copyWith({Value<int>? id, Value<DateTime>? date}) {
    return ActivityLogCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLogCompanion(')
          ..write('id: $id, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DayEntriesTable dayEntries = $DayEntriesTable(this);
  late final $StreakAdjustmentsTable streakAdjustments =
      $StreakAdjustmentsTable(this);
  late final $ActivityLogTable activityLog = $ActivityLogTable(this);
  late final Index idxDayEntriesDate = Index('idx_day_entries_date',
      'CREATE INDEX idx_day_entries_date ON day_entries (date)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [dayEntries, streakAdjustments, activityLog, idxDayEntriesDate];
}

typedef $$DayEntriesTableCreateCompanionBuilder = DayEntriesCompanion Function({
  Value<int> id,
  required DateTime date,
  required String photoPath,
  Value<String?> thumbnailPath,
  required int moodRating,
  Value<String?> note,
  Value<String?> location,
  Value<String?> weatherTemp,
  Value<String?> weatherIcon,
});
typedef $$DayEntriesTableUpdateCompanionBuilder = DayEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> photoPath,
  Value<String?> thumbnailPath,
  Value<int> moodRating,
  Value<String?> note,
  Value<String?> location,
  Value<String?> weatherTemp,
  Value<String?> weatherIcon,
});

class $$DayEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get moodRating => $composableBuilder(
      column: $table.moodRating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weatherTemp => $composableBuilder(
      column: $table.weatherTemp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weatherIcon => $composableBuilder(
      column: $table.weatherIcon, builder: (column) => ColumnFilters(column));
}

class $$DayEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get moodRating => $composableBuilder(
      column: $table.moodRating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weatherTemp => $composableBuilder(
      column: $table.weatherTemp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weatherIcon => $composableBuilder(
      column: $table.weatherIcon, builder: (column) => ColumnOrderings(column));
}

class $$DayEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<int> get moodRating => $composableBuilder(
      column: $table.moodRating, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get weatherTemp => $composableBuilder(
      column: $table.weatherTemp, builder: (column) => column);

  GeneratedColumn<String> get weatherIcon => $composableBuilder(
      column: $table.weatherIcon, builder: (column) => column);
}

class $$DayEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DayEntriesTable,
    DayEntry,
    $$DayEntriesTableFilterComposer,
    $$DayEntriesTableOrderingComposer,
    $$DayEntriesTableAnnotationComposer,
    $$DayEntriesTableCreateCompanionBuilder,
    $$DayEntriesTableUpdateCompanionBuilder,
    (DayEntry, BaseReferences<_$AppDatabase, $DayEntriesTable, DayEntry>),
    DayEntry,
    PrefetchHooks Function()> {
  $$DayEntriesTableTableManager(_$AppDatabase db, $DayEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<int> moodRating = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> weatherTemp = const Value.absent(),
            Value<String?> weatherIcon = const Value.absent(),
          }) =>
              DayEntriesCompanion(
            id: id,
            date: date,
            photoPath: photoPath,
            thumbnailPath: thumbnailPath,
            moodRating: moodRating,
            note: note,
            location: location,
            weatherTemp: weatherTemp,
            weatherIcon: weatherIcon,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String photoPath,
            Value<String?> thumbnailPath = const Value.absent(),
            required int moodRating,
            Value<String?> note = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> weatherTemp = const Value.absent(),
            Value<String?> weatherIcon = const Value.absent(),
          }) =>
              DayEntriesCompanion.insert(
            id: id,
            date: date,
            photoPath: photoPath,
            thumbnailPath: thumbnailPath,
            moodRating: moodRating,
            note: note,
            location: location,
            weatherTemp: weatherTemp,
            weatherIcon: weatherIcon,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DayEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DayEntriesTable,
    DayEntry,
    $$DayEntriesTableFilterComposer,
    $$DayEntriesTableOrderingComposer,
    $$DayEntriesTableAnnotationComposer,
    $$DayEntriesTableCreateCompanionBuilder,
    $$DayEntriesTableUpdateCompanionBuilder,
    (DayEntry, BaseReferences<_$AppDatabase, $DayEntriesTable, DayEntry>),
    DayEntry,
    PrefetchHooks Function()>;
typedef $$StreakAdjustmentsTableCreateCompanionBuilder
    = StreakAdjustmentsCompanion Function({
  Value<int> id,
  required DateTime date,
  Value<DateTime> createdAt,
  required StreakAdjustmentType type,
});
typedef $$StreakAdjustmentsTableUpdateCompanionBuilder
    = StreakAdjustmentsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<DateTime> createdAt,
  Value<StreakAdjustmentType> type,
});

class $$StreakAdjustmentsTableFilterComposer
    extends Composer<_$AppDatabase, $StreakAdjustmentsTable> {
  $$StreakAdjustmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<StreakAdjustmentType, StreakAdjustmentType,
          int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$StreakAdjustmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StreakAdjustmentsTable> {
  $$StreakAdjustmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$StreakAdjustmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreakAdjustmentsTable> {
  $$StreakAdjustmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StreakAdjustmentType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$StreakAdjustmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StreakAdjustmentsTable,
    StreakAdjustment,
    $$StreakAdjustmentsTableFilterComposer,
    $$StreakAdjustmentsTableOrderingComposer,
    $$StreakAdjustmentsTableAnnotationComposer,
    $$StreakAdjustmentsTableCreateCompanionBuilder,
    $$StreakAdjustmentsTableUpdateCompanionBuilder,
    (
      StreakAdjustment,
      BaseReferences<_$AppDatabase, $StreakAdjustmentsTable, StreakAdjustment>
    ),
    StreakAdjustment,
    PrefetchHooks Function()> {
  $$StreakAdjustmentsTableTableManager(
      _$AppDatabase db, $StreakAdjustmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakAdjustmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakAdjustmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakAdjustmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<StreakAdjustmentType> type = const Value.absent(),
          }) =>
              StreakAdjustmentsCompanion(
            id: id,
            date: date,
            createdAt: createdAt,
            type: type,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<DateTime> createdAt = const Value.absent(),
            required StreakAdjustmentType type,
          }) =>
              StreakAdjustmentsCompanion.insert(
            id: id,
            date: date,
            createdAt: createdAt,
            type: type,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StreakAdjustmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StreakAdjustmentsTable,
    StreakAdjustment,
    $$StreakAdjustmentsTableFilterComposer,
    $$StreakAdjustmentsTableOrderingComposer,
    $$StreakAdjustmentsTableAnnotationComposer,
    $$StreakAdjustmentsTableCreateCompanionBuilder,
    $$StreakAdjustmentsTableUpdateCompanionBuilder,
    (
      StreakAdjustment,
      BaseReferences<_$AppDatabase, $StreakAdjustmentsTable, StreakAdjustment>
    ),
    StreakAdjustment,
    PrefetchHooks Function()>;
typedef $$ActivityLogTableCreateCompanionBuilder = ActivityLogCompanion
    Function({
  Value<int> id,
  required DateTime date,
});
typedef $$ActivityLogTableUpdateCompanionBuilder = ActivityLogCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
});

class $$ActivityLogTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityLogTable> {
  $$ActivityLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));
}

class $$ActivityLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityLogTable> {
  $$ActivityLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));
}

class $$ActivityLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityLogTable> {
  $$ActivityLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$ActivityLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivityLogTable,
    ActivityLogData,
    $$ActivityLogTableFilterComposer,
    $$ActivityLogTableOrderingComposer,
    $$ActivityLogTableAnnotationComposer,
    $$ActivityLogTableCreateCompanionBuilder,
    $$ActivityLogTableUpdateCompanionBuilder,
    (
      ActivityLogData,
      BaseReferences<_$AppDatabase, $ActivityLogTable, ActivityLogData>
    ),
    ActivityLogData,
    PrefetchHooks Function()> {
  $$ActivityLogTableTableManager(_$AppDatabase db, $ActivityLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
          }) =>
              ActivityLogCompanion(
            id: id,
            date: date,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
          }) =>
              ActivityLogCompanion.insert(
            id: id,
            date: date,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivityLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivityLogTable,
    ActivityLogData,
    $$ActivityLogTableFilterComposer,
    $$ActivityLogTableOrderingComposer,
    $$ActivityLogTableAnnotationComposer,
    $$ActivityLogTableCreateCompanionBuilder,
    $$ActivityLogTableUpdateCompanionBuilder,
    (
      ActivityLogData,
      BaseReferences<_$AppDatabase, $ActivityLogTable, ActivityLogData>
    ),
    ActivityLogData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db, _db.dayEntries);
  $$StreakAdjustmentsTableTableManager get streakAdjustments =>
      $$StreakAdjustmentsTableTableManager(_db, _db.streakAdjustments);
  $$ActivityLogTableTableManager get activityLog =>
      $$ActivityLogTableTableManager(_db, _db.activityLog);
}
