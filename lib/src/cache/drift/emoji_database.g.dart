// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_database.dart';

// ignore_for_file: type=lint
class $EmojiRecordsTable extends EmojiRecords
    with TableInfo<$EmojiRecordsTable, StoredEmojiRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmojiRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localOnlyMeta = const VerificationMeta(
    'localOnly',
  );
  @override
  late final GeneratedColumn<bool> localOnly = GeneratedColumn<bool>(
    'local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_only" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isSensitiveMeta = const VerificationMeta(
    'isSensitive',
  );
  @override
  late final GeneratedColumn<bool> isSensitive = GeneratedColumn<bool>(
    'is_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sensitive" IN (0, 1))',
    ),
  );
  static const VerificationMeta _allowRoleIdsMeta = const VerificationMeta(
    'allowRoleIds',
  );
  @override
  late final GeneratedColumn<String> allowRoleIds = GeneratedColumn<String>(
    'allow_role_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    aliases,
    category,
    url,
    localOnly,
    isSensitive,
    allowRoleIds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emoji_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredEmojiRecord> instance, {
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
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasesMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('local_only')) {
      context.handle(
        _localOnlyMeta,
        localOnly.isAcceptableOrUnknown(data['local_only']!, _localOnlyMeta),
      );
    } else if (isInserting) {
      context.missing(_localOnlyMeta);
    }
    if (data.containsKey('is_sensitive')) {
      context.handle(
        _isSensitiveMeta,
        isSensitive.isAcceptableOrUnknown(
          data['is_sensitive']!,
          _isSensitiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSensitiveMeta);
    }
    if (data.containsKey('allow_role_ids')) {
      context.handle(
        _allowRoleIdsMeta,
        allowRoleIds.isAcceptableOrUnknown(
          data['allow_role_ids']!,
          _allowRoleIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowRoleIdsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  StoredEmojiRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredEmojiRecord(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      localOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_only'],
      )!,
      isSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sensitive'],
      )!,
      allowRoleIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allow_role_ids'],
      )!,
    );
  }

  @override
  $EmojiRecordsTable createAlias(String alias) {
    return $EmojiRecordsTable(attachedDatabase, alias);
  }
}

class StoredEmojiRecord extends DataClass
    implements Insertable<StoredEmojiRecord> {
  final String name;
  final String aliases;
  final String? category;
  final String url;
  final bool localOnly;
  final bool isSensitive;
  final String allowRoleIds;
  const StoredEmojiRecord({
    required this.name,
    required this.aliases,
    this.category,
    required this.url,
    required this.localOnly,
    required this.isSensitive,
    required this.allowRoleIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['aliases'] = Variable<String>(aliases);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['url'] = Variable<String>(url);
    map['local_only'] = Variable<bool>(localOnly);
    map['is_sensitive'] = Variable<bool>(isSensitive);
    map['allow_role_ids'] = Variable<String>(allowRoleIds);
    return map;
  }

  EmojiRecordsCompanion toCompanion(bool nullToAbsent) {
    return EmojiRecordsCompanion(
      name: Value(name),
      aliases: Value(aliases),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      url: Value(url),
      localOnly: Value(localOnly),
      isSensitive: Value(isSensitive),
      allowRoleIds: Value(allowRoleIds),
    );
  }

  factory StoredEmojiRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredEmojiRecord(
      name: serializer.fromJson<String>(json['name']),
      aliases: serializer.fromJson<String>(json['aliases']),
      category: serializer.fromJson<String?>(json['category']),
      url: serializer.fromJson<String>(json['url']),
      localOnly: serializer.fromJson<bool>(json['localOnly']),
      isSensitive: serializer.fromJson<bool>(json['isSensitive']),
      allowRoleIds: serializer.fromJson<String>(json['allowRoleIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'aliases': serializer.toJson<String>(aliases),
      'category': serializer.toJson<String?>(category),
      'url': serializer.toJson<String>(url),
      'localOnly': serializer.toJson<bool>(localOnly),
      'isSensitive': serializer.toJson<bool>(isSensitive),
      'allowRoleIds': serializer.toJson<String>(allowRoleIds),
    };
  }

  StoredEmojiRecord copyWith({
    String? name,
    String? aliases,
    Value<String?> category = const Value.absent(),
    String? url,
    bool? localOnly,
    bool? isSensitive,
    String? allowRoleIds,
  }) => StoredEmojiRecord(
    name: name ?? this.name,
    aliases: aliases ?? this.aliases,
    category: category.present ? category.value : this.category,
    url: url ?? this.url,
    localOnly: localOnly ?? this.localOnly,
    isSensitive: isSensitive ?? this.isSensitive,
    allowRoleIds: allowRoleIds ?? this.allowRoleIds,
  );
  StoredEmojiRecord copyWithCompanion(EmojiRecordsCompanion data) {
    return StoredEmojiRecord(
      name: data.name.present ? data.name.value : this.name,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      category: data.category.present ? data.category.value : this.category,
      url: data.url.present ? data.url.value : this.url,
      localOnly: data.localOnly.present ? data.localOnly.value : this.localOnly,
      isSensitive: data.isSensitive.present
          ? data.isSensitive.value
          : this.isSensitive,
      allowRoleIds: data.allowRoleIds.present
          ? data.allowRoleIds.value
          : this.allowRoleIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredEmojiRecord(')
          ..write('name: $name, ')
          ..write('aliases: $aliases, ')
          ..write('category: $category, ')
          ..write('url: $url, ')
          ..write('localOnly: $localOnly, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('allowRoleIds: $allowRoleIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    name,
    aliases,
    category,
    url,
    localOnly,
    isSensitive,
    allowRoleIds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredEmojiRecord &&
          other.name == this.name &&
          other.aliases == this.aliases &&
          other.category == this.category &&
          other.url == this.url &&
          other.localOnly == this.localOnly &&
          other.isSensitive == this.isSensitive &&
          other.allowRoleIds == this.allowRoleIds);
}

class EmojiRecordsCompanion extends UpdateCompanion<StoredEmojiRecord> {
  final Value<String> name;
  final Value<String> aliases;
  final Value<String?> category;
  final Value<String> url;
  final Value<bool> localOnly;
  final Value<bool> isSensitive;
  final Value<String> allowRoleIds;
  final Value<int> rowid;
  const EmojiRecordsCompanion({
    this.name = const Value.absent(),
    this.aliases = const Value.absent(),
    this.category = const Value.absent(),
    this.url = const Value.absent(),
    this.localOnly = const Value.absent(),
    this.isSensitive = const Value.absent(),
    this.allowRoleIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmojiRecordsCompanion.insert({
    required String name,
    required String aliases,
    this.category = const Value.absent(),
    required String url,
    required bool localOnly,
    required bool isSensitive,
    required String allowRoleIds,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       aliases = Value(aliases),
       url = Value(url),
       localOnly = Value(localOnly),
       isSensitive = Value(isSensitive),
       allowRoleIds = Value(allowRoleIds);
  static Insertable<StoredEmojiRecord> custom({
    Expression<String>? name,
    Expression<String>? aliases,
    Expression<String>? category,
    Expression<String>? url,
    Expression<bool>? localOnly,
    Expression<bool>? isSensitive,
    Expression<String>? allowRoleIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (aliases != null) 'aliases': aliases,
      if (category != null) 'category': category,
      if (url != null) 'url': url,
      if (localOnly != null) 'local_only': localOnly,
      if (isSensitive != null) 'is_sensitive': isSensitive,
      if (allowRoleIds != null) 'allow_role_ids': allowRoleIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmojiRecordsCompanion copyWith({
    Value<String>? name,
    Value<String>? aliases,
    Value<String?>? category,
    Value<String>? url,
    Value<bool>? localOnly,
    Value<bool>? isSensitive,
    Value<String>? allowRoleIds,
    Value<int>? rowid,
  }) {
    return EmojiRecordsCompanion(
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      url: url ?? this.url,
      localOnly: localOnly ?? this.localOnly,
      isSensitive: isSensitive ?? this.isSensitive,
      allowRoleIds: allowRoleIds ?? this.allowRoleIds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (localOnly.present) {
      map['local_only'] = Variable<bool>(localOnly.value);
    }
    if (isSensitive.present) {
      map['is_sensitive'] = Variable<bool>(isSensitive.value);
    }
    if (allowRoleIds.present) {
      map['allow_role_ids'] = Variable<String>(allowRoleIds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmojiRecordsCompanion(')
          ..write('name: $name, ')
          ..write('aliases: $aliases, ')
          ..write('category: $category, ')
          ..write('url: $url, ')
          ..write('localOnly: $localOnly, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('allowRoleIds: $allowRoleIds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final int id;
  final DateTime lastSyncedAt;
  const SyncMetadataData({required this.id, required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      id: Value(id),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      id: serializer.fromJson<int>(json['id']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  SyncMetadataData copyWith({int? id, DateTime? lastSyncedAt}) =>
      SyncMetadataData(
        id: id ?? this.id,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      id: data.id.present ? data.id.value : this.id,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.id == this.id &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<int> id;
  final Value<DateTime> lastSyncedAt;
  const SyncMetadataCompanion({
    this.id = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastSyncedAt,
  }) : lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncMetadataData> custom({
    Expression<int>? id,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? lastSyncedAt,
  }) {
    return SyncMetadataCompanion(
      id: id ?? this.id,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$EmojiDatabase extends GeneratedDatabase {
  _$EmojiDatabase(QueryExecutor e) : super(e);
  $EmojiDatabaseManager get managers => $EmojiDatabaseManager(this);
  late final $EmojiRecordsTable emojiRecords = $EmojiRecordsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    emojiRecords,
    syncMetadata,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$EmojiRecordsTableCreateCompanionBuilder =
    EmojiRecordsCompanion Function({
      required String name,
      required String aliases,
      Value<String?> category,
      required String url,
      required bool localOnly,
      required bool isSensitive,
      required String allowRoleIds,
      Value<int> rowid,
    });
typedef $$EmojiRecordsTableUpdateCompanionBuilder =
    EmojiRecordsCompanion Function({
      Value<String> name,
      Value<String> aliases,
      Value<String?> category,
      Value<String> url,
      Value<bool> localOnly,
      Value<bool> isSensitive,
      Value<String> allowRoleIds,
      Value<int> rowid,
    });

class $$EmojiRecordsTableFilterComposer
    extends Composer<_$EmojiDatabase, $EmojiRecordsTable> {
  $$EmojiRecordsTableFilterComposer({
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

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localOnly => $composableBuilder(
    column: $table.localOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowRoleIds => $composableBuilder(
    column: $table.allowRoleIds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmojiRecordsTableOrderingComposer
    extends Composer<_$EmojiDatabase, $EmojiRecordsTable> {
  $$EmojiRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localOnly => $composableBuilder(
    column: $table.localOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowRoleIds => $composableBuilder(
    column: $table.allowRoleIds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmojiRecordsTableAnnotationComposer
    extends Composer<_$EmojiDatabase, $EmojiRecordsTable> {
  $$EmojiRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<bool> get localOnly =>
      $composableBuilder(column: $table.localOnly, builder: (column) => column);

  GeneratedColumn<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allowRoleIds => $composableBuilder(
    column: $table.allowRoleIds,
    builder: (column) => column,
  );
}

class $$EmojiRecordsTableTableManager
    extends
        RootTableManager<
          _$EmojiDatabase,
          $EmojiRecordsTable,
          StoredEmojiRecord,
          $$EmojiRecordsTableFilterComposer,
          $$EmojiRecordsTableOrderingComposer,
          $$EmojiRecordsTableAnnotationComposer,
          $$EmojiRecordsTableCreateCompanionBuilder,
          $$EmojiRecordsTableUpdateCompanionBuilder,
          (
            StoredEmojiRecord,
            BaseReferences<
              _$EmojiDatabase,
              $EmojiRecordsTable,
              StoredEmojiRecord
            >,
          ),
          StoredEmojiRecord,
          PrefetchHooks Function()
        > {
  $$EmojiRecordsTableTableManager(_$EmojiDatabase db, $EmojiRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmojiRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmojiRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmojiRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<bool> localOnly = const Value.absent(),
                Value<bool> isSensitive = const Value.absent(),
                Value<String> allowRoleIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmojiRecordsCompanion(
                name: name,
                aliases: aliases,
                category: category,
                url: url,
                localOnly: localOnly,
                isSensitive: isSensitive,
                allowRoleIds: allowRoleIds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String aliases,
                Value<String?> category = const Value.absent(),
                required String url,
                required bool localOnly,
                required bool isSensitive,
                required String allowRoleIds,
                Value<int> rowid = const Value.absent(),
              }) => EmojiRecordsCompanion.insert(
                name: name,
                aliases: aliases,
                category: category,
                url: url,
                localOnly: localOnly,
                isSensitive: isSensitive,
                allowRoleIds: allowRoleIds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmojiRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$EmojiDatabase,
      $EmojiRecordsTable,
      StoredEmojiRecord,
      $$EmojiRecordsTableFilterComposer,
      $$EmojiRecordsTableOrderingComposer,
      $$EmojiRecordsTableAnnotationComposer,
      $$EmojiRecordsTableCreateCompanionBuilder,
      $$EmojiRecordsTableUpdateCompanionBuilder,
      (
        StoredEmojiRecord,
        BaseReferences<_$EmojiDatabase, $EmojiRecordsTable, StoredEmojiRecord>,
      ),
      StoredEmojiRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<int> id,
      required DateTime lastSyncedAt,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<int> id,
      Value<DateTime> lastSyncedAt,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$EmojiDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
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

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$EmojiDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
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

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$EmojiDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$EmojiDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<
              _$EmojiDatabase,
              $SyncMetadataTable,
              SyncMetadataData
            >,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$EmojiDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
              }) => SyncMetadataCompanion(id: id, lastSyncedAt: lastSyncedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime lastSyncedAt,
              }) => SyncMetadataCompanion.insert(
                id: id,
                lastSyncedAt: lastSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$EmojiDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$EmojiDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;

class $EmojiDatabaseManager {
  final _$EmojiDatabase _db;
  $EmojiDatabaseManager(this._db);
  $$EmojiRecordsTableTableManager get emojiRecords =>
      $$EmojiRecordsTableTableManager(_db, _db.emojiRecords);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
