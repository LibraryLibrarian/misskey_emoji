// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_database.dart';

// ignore_for_file: type=lint
class $MigrationRecordsTable extends MigrationRecords
    with TableInfo<$MigrationRecordsTable, MigrationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  MigrationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationRecord(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $MigrationRecordsTable createAlias(String alias) {
    return $MigrationRecordsTable(attachedDatabase, alias);
  }
}

class MigrationRecord extends DataClass implements Insertable<MigrationRecord> {
  final String name;
  const MigrationRecord({required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    return map;
  }

  MigrationRecordsCompanion toCompanion(bool nullToAbsent) {
    return MigrationRecordsCompanion(name: Value(name));
  }

  factory MigrationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationRecord(name: serializer.fromJson<String>(json['name']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'name': serializer.toJson<String>(name)};
  }

  MigrationRecord copyWith({String? name}) =>
      MigrationRecord(name: name ?? this.name);
  MigrationRecord copyWithCompanion(MigrationRecordsCompanion data) {
    return MigrationRecord(
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRecord(')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => name.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationRecord && other.name == this.name);
}

class MigrationRecordsCompanion extends UpdateCompanion<MigrationRecord> {
  final Value<String> name;
  final Value<int> rowid;
  const MigrationRecordsCompanion({
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationRecordsCompanion.insert({
    required String name,
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<MigrationRecord> custom({
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationRecordsCompanion copyWith({Value<String>? name, Value<int>? rowid}) {
    return MigrationRecordsCompanion(
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRecordsCompanion(')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationMetadataTable extends MigrationMetadata
    with TableInfo<$MigrationMetadataTable, MigrationMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MigrationMetadataTable createAlias(String alias) {
    return $MigrationMetadataTable(attachedDatabase, alias);
  }
}

class MigrationMetadataData extends DataClass
    implements Insertable<MigrationMetadataData> {
  final int id;
  final DateTime syncedAt;
  const MigrationMetadataData({required this.id, required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MigrationMetadataCompanion toCompanion(bool nullToAbsent) {
    return MigrationMetadataCompanion(id: Value(id), syncedAt: Value(syncedAt));
  }

  factory MigrationMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationMetadataData(
      id: serializer.fromJson<int>(json['id']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MigrationMetadataData copyWith({int? id, DateTime? syncedAt}) =>
      MigrationMetadataData(
        id: id ?? this.id,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  MigrationMetadataData copyWithCompanion(MigrationMetadataCompanion data) {
    return MigrationMetadataData(
      id: data.id.present ? data.id.value : this.id,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationMetadataData(')
          ..write('id: $id, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationMetadataData &&
          other.id == this.id &&
          other.syncedAt == this.syncedAt);
}

class MigrationMetadataCompanion
    extends UpdateCompanion<MigrationMetadataData> {
  final Value<int> id;
  final Value<DateTime> syncedAt;
  const MigrationMetadataCompanion({
    this.id = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  MigrationMetadataCompanion.insert({
    this.id = const Value.absent(),
    required DateTime syncedAt,
  }) : syncedAt = Value(syncedAt);
  static Insertable<MigrationMetadataData> custom({
    Expression<int>? id,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  MigrationMetadataCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? syncedAt,
  }) {
    return MigrationMetadataCompanion(
      id: id ?? this.id,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationMetadataCompanion(')
          ..write('id: $id, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$MigrationDatabaseV1 extends GeneratedDatabase {
  _$MigrationDatabaseV1(QueryExecutor e) : super(e);
  $MigrationDatabaseV1Manager get managers => $MigrationDatabaseV1Manager(this);
  late final $MigrationRecordsTable migrationRecords = $MigrationRecordsTable(
    this,
  );
  late final $MigrationMetadataTable migrationMetadata =
      $MigrationMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    migrationRecords,
    migrationMetadata,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MigrationRecordsTableCreateCompanionBuilder =
    MigrationRecordsCompanion Function({
      required String name,
      Value<int> rowid,
    });
typedef $$MigrationRecordsTableUpdateCompanionBuilder =
    MigrationRecordsCompanion Function({Value<String> name, Value<int> rowid});

class $$MigrationRecordsTableFilterComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationRecordsTable> {
  $$MigrationRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationRecordsTableOrderingComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationRecordsTable> {
  $$MigrationRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationRecordsTableAnnotationComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationRecordsTable> {
  $$MigrationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$MigrationRecordsTableTableManager
    extends
        RootTableManager<
          _$MigrationDatabaseV1,
          $MigrationRecordsTable,
          MigrationRecord,
          $$MigrationRecordsTableFilterComposer,
          $$MigrationRecordsTableOrderingComposer,
          $$MigrationRecordsTableAnnotationComposer,
          $$MigrationRecordsTableCreateCompanionBuilder,
          $$MigrationRecordsTableUpdateCompanionBuilder,
          (
            MigrationRecord,
            BaseReferences<
              _$MigrationDatabaseV1,
              $MigrationRecordsTable,
              MigrationRecord
            >,
          ),
          MigrationRecord,
          PrefetchHooks Function()
        > {
  $$MigrationRecordsTableTableManager(
    _$MigrationDatabaseV1 db,
    $MigrationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationRecordsCompanion(name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => MigrationRecordsCompanion.insert(name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$MigrationDatabaseV1,
      $MigrationRecordsTable,
      MigrationRecord,
      $$MigrationRecordsTableFilterComposer,
      $$MigrationRecordsTableOrderingComposer,
      $$MigrationRecordsTableAnnotationComposer,
      $$MigrationRecordsTableCreateCompanionBuilder,
      $$MigrationRecordsTableUpdateCompanionBuilder,
      (
        MigrationRecord,
        BaseReferences<
          _$MigrationDatabaseV1,
          $MigrationRecordsTable,
          MigrationRecord
        >,
      ),
      MigrationRecord,
      PrefetchHooks Function()
    >;
typedef $$MigrationMetadataTableCreateCompanionBuilder =
    MigrationMetadataCompanion Function({
      Value<int> id,
      required DateTime syncedAt,
    });
typedef $$MigrationMetadataTableUpdateCompanionBuilder =
    MigrationMetadataCompanion Function({
      Value<int> id,
      Value<DateTime> syncedAt,
    });

class $$MigrationMetadataTableFilterComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationMetadataTable> {
  $$MigrationMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationMetadataTableOrderingComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationMetadataTable> {
  $$MigrationMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationMetadataTableAnnotationComposer
    extends Composer<_$MigrationDatabaseV1, $MigrationMetadataTable> {
  $$MigrationMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MigrationMetadataTableTableManager
    extends
        RootTableManager<
          _$MigrationDatabaseV1,
          $MigrationMetadataTable,
          MigrationMetadataData,
          $$MigrationMetadataTableFilterComposer,
          $$MigrationMetadataTableOrderingComposer,
          $$MigrationMetadataTableAnnotationComposer,
          $$MigrationMetadataTableCreateCompanionBuilder,
          $$MigrationMetadataTableUpdateCompanionBuilder,
          (
            MigrationMetadataData,
            BaseReferences<
              _$MigrationDatabaseV1,
              $MigrationMetadataTable,
              MigrationMetadataData
            >,
          ),
          MigrationMetadataData,
          PrefetchHooks Function()
        > {
  $$MigrationMetadataTableTableManager(
    _$MigrationDatabaseV1 db,
    $MigrationMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => MigrationMetadataCompanion(id: id, syncedAt: syncedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime syncedAt,
              }) =>
                  MigrationMetadataCompanion.insert(id: id, syncedAt: syncedAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$MigrationDatabaseV1,
      $MigrationMetadataTable,
      MigrationMetadataData,
      $$MigrationMetadataTableFilterComposer,
      $$MigrationMetadataTableOrderingComposer,
      $$MigrationMetadataTableAnnotationComposer,
      $$MigrationMetadataTableCreateCompanionBuilder,
      $$MigrationMetadataTableUpdateCompanionBuilder,
      (
        MigrationMetadataData,
        BaseReferences<
          _$MigrationDatabaseV1,
          $MigrationMetadataTable,
          MigrationMetadataData
        >,
      ),
      MigrationMetadataData,
      PrefetchHooks Function()
    >;

class $MigrationDatabaseV1Manager {
  final _$MigrationDatabaseV1 _db;
  $MigrationDatabaseV1Manager(this._db);
  $$MigrationRecordsTableTableManager get migrationRecords =>
      $$MigrationRecordsTableTableManager(_db, _db.migrationRecords);
  $$MigrationMetadataTableTableManager get migrationMetadata =>
      $$MigrationMetadataTableTableManager(_db, _db.migrationMetadata);
}
