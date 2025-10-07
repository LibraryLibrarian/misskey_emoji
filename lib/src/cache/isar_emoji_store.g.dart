// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_emoji_store.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEmojiRecordEntityCollection on Isar {
  IsarCollection<EmojiRecordEntity> get emojiRecordEntitys => this.collection();
}

const EmojiRecordEntitySchema = CollectionSchema(
  name: r'EmojiRecordEntity',
  id: 7229933210852124576,
  properties: {
    r'aliases': PropertySchema(
      id: 0,
      name: r'aliases',
      type: IsarType.stringList,
    ),
    r'allowRoleIds': PropertySchema(
      id: 1,
      name: r'allowRoleIds',
      type: IsarType.stringList,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'denyRoleIds': PropertySchema(
      id: 3,
      name: r'denyRoleIds',
      type: IsarType.stringList,
    ),
    r'isSensitive': PropertySchema(
      id: 4,
      name: r'isSensitive',
      type: IsarType.bool,
    ),
    r'localOnly': PropertySchema(
      id: 5,
      name: r'localOnly',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(id: 6, name: r'name', type: IsarType.string),
    r'url': PropertySchema(id: 7, name: r'url', type: IsarType.string),
  },

  estimateSize: _emojiRecordEntityEstimateSize,
  serialize: _emojiRecordEntitySerialize,
  deserialize: _emojiRecordEntityDeserialize,
  deserializeProp: _emojiRecordEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _emojiRecordEntityGetId,
  getLinks: _emojiRecordEntityGetLinks,
  attach: _emojiRecordEntityAttach,
  version: '3.3.0-dev.3',
);

int _emojiRecordEntityEstimateSize(
  EmojiRecordEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aliases.length * 3;
  {
    for (var i = 0; i < object.aliases.length; i++) {
      final value = object.aliases[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.allowRoleIds.length * 3;
  {
    for (var i = 0; i < object.allowRoleIds.length; i++) {
      final value = object.allowRoleIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.denyRoleIds.length * 3;
  {
    for (var i = 0; i < object.denyRoleIds.length; i++) {
      final value = object.denyRoleIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _emojiRecordEntitySerialize(
  EmojiRecordEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.aliases);
  writer.writeStringList(offsets[1], object.allowRoleIds);
  writer.writeString(offsets[2], object.category);
  writer.writeStringList(offsets[3], object.denyRoleIds);
  writer.writeBool(offsets[4], object.isSensitive);
  writer.writeBool(offsets[5], object.localOnly);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.url);
}

EmojiRecordEntity _emojiRecordEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EmojiRecordEntity();
  object.aliases = reader.readStringList(offsets[0]) ?? [];
  object.allowRoleIds = reader.readStringList(offsets[1]) ?? [];
  object.category = reader.readStringOrNull(offsets[2]);
  object.denyRoleIds = reader.readStringList(offsets[3]) ?? [];
  object.id = id;
  object.isSensitive = reader.readBool(offsets[4]);
  object.localOnly = reader.readBool(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.url = reader.readString(offsets[7]);
  return object;
}

P _emojiRecordEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _emojiRecordEntityGetId(EmojiRecordEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _emojiRecordEntityGetLinks(
  EmojiRecordEntity object,
) {
  return [];
}

void _emojiRecordEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  EmojiRecordEntity object,
) {
  object.id = id;
}

extension EmojiRecordEntityQueryWhereSort
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QWhere> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EmojiRecordEntityQueryWhere
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QWhereClause> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension EmojiRecordEntityQueryFilter
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QFilterCondition> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aliases',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'aliases',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'aliases', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'aliases', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', length, true, length, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, true, 0, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, false, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, true, length, include);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', length, include, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  aliasesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'allowRoleIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'allowRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'allowRoleIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'allowRoleIds', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'allowRoleIds', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowRoleIds', length, true, length, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowRoleIds', 0, true, 0, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowRoleIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowRoleIds', 0, true, length, include);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowRoleIds', length, include, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  allowRoleIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'allowRoleIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'denyRoleIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'denyRoleIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'denyRoleIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'denyRoleIds', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'denyRoleIds', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'denyRoleIds', length, true, length, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'denyRoleIds', 0, true, 0, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'denyRoleIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'denyRoleIds', 0, true, length, include);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'denyRoleIds', length, include, 999999, true);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  denyRoleIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'denyRoleIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  isSensitiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSensitive', value: value),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  localOnlyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localOnly', value: value),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterFilterCondition>
  urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }
}

extension EmojiRecordEntityQueryObject
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QFilterCondition> {}

extension EmojiRecordEntityQueryLinks
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QFilterCondition> {}

extension EmojiRecordEntityQuerySortBy
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QSortBy> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByIsSensitive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSensitive', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByIsSensitiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSensitive', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension EmojiRecordEntityQuerySortThenBy
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QSortThenBy> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByIsSensitive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSensitive', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByIsSensitiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSensitive', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QAfterSortBy>
  thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension EmojiRecordEntityQueryWhereDistinct
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct> {
  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByAliases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aliases');
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByAllowRoleIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowRoleIds');
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByDenyRoleIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'denyRoleIds');
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByIsSensitive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSensitive');
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct>
  distinctByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localOnly');
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QDistinct> distinctByUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension EmojiRecordEntityQueryProperty
    on QueryBuilder<EmojiRecordEntity, EmojiRecordEntity, QQueryProperty> {
  QueryBuilder<EmojiRecordEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EmojiRecordEntity, List<String>, QQueryOperations>
  aliasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aliases');
    });
  }

  QueryBuilder<EmojiRecordEntity, List<String>, QQueryOperations>
  allowRoleIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowRoleIds');
    });
  }

  QueryBuilder<EmojiRecordEntity, String?, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<EmojiRecordEntity, List<String>, QQueryOperations>
  denyRoleIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'denyRoleIds');
    });
  }

  QueryBuilder<EmojiRecordEntity, bool, QQueryOperations>
  isSensitiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSensitive');
    });
  }

  QueryBuilder<EmojiRecordEntity, bool, QQueryOperations> localOnlyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localOnly');
    });
  }

  QueryBuilder<EmojiRecordEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<EmojiRecordEntity, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
