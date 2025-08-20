import 'package:json_annotation/json_annotation.dart';

part 'emoji_dto.g.dart';

/// Misskey API が返す絵文字の生データ（DTO）。
@JsonSerializable()
class EmojiDto {
  final String name;
  final List<String> aliases;
  final String? category;
  final String url;
  final bool? localOnly;
  final bool? isSensitive;

  @JsonKey(name: 'roleIdsThatCanBeUsedThisEmojiAsReaction')
  final List<String>? allowRoleIds;

  @JsonKey(name: 'roleIdsThatCanNotBeUsedThisEmojiAsReaction')
  final List<String>? denyRoleIds;

  const EmojiDto({
    required this.name,
    required this.aliases,
    required this.url,
    this.category,
    this.localOnly,
    this.isSensitive,
    this.allowRoleIds,
    this.denyRoleIds,
  });

  factory EmojiDto.fromJson(Map<String, dynamic> json) =>
      _$EmojiDtoFromJson(json);
  Map<String, dynamic> toJson() => _$EmojiDtoToJson(this);
}
