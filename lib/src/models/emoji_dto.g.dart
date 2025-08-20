// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmojiDto _$EmojiDtoFromJson(Map<String, dynamic> json) => EmojiDto(
      name: json['name'] as String,
      aliases:
          (json['aliases'] as List<dynamic>).map((e) => e as String).toList(),
      url: json['url'] as String,
      category: json['category'] as String?,
      localOnly: json['localOnly'] as bool?,
      isSensitive: json['isSensitive'] as bool?,
      allowRoleIds:
          (json['roleIdsThatCanBeUsedThisEmojiAsReaction'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      denyRoleIds:
          (json['roleIdsThatCanNotBeUsedThisEmojiAsReaction'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$EmojiDtoToJson(EmojiDto instance) => <String, dynamic>{
      'name': instance.name,
      'aliases': instance.aliases,
      'category': instance.category,
      'url': instance.url,
      'localOnly': instance.localOnly,
      'isSensitive': instance.isSensitive,
      'roleIdsThatCanBeUsedThisEmojiAsReaction': instance.allowRoleIds,
      'roleIdsThatCanNotBeUsedThisEmojiAsReaction': instance.denyRoleIds,
    };
