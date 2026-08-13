# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The following breaking changes are planned for the next major release (2.0.0).

### Added

- Added the `EmojiSource` synchronization boundary and the `MisskeyClientEmojiSource` adapter

### Changed

- **Breaking:** Replaced the `MisskeyEmojiApi` and optional `MetaClient` constructor parameters on emoji catalogs with a required `EmojiSource`
- Replaced the `misskey_api_core` dependency with `misskey_client`
- Aligned the Isar runtime and generator on 3.3.2 for the regenerated cache schema

### Removed

- **Breaking:** Removed `EmojiRecord.denyRoleIds`, which represented a misskey.io fork-specific field that does not exist in upstream Misskey
- Removed the obsolete `/api/meta` emoji prefill path because upstream Misskey has served custom emoji through `/api/emojis` since v13
- Removed `MisskeyEmojiApi` and the internal `EmojiDto`; `MisskeyClientEmojiSource` now maps `MisskeyCustomEmoji` directly to `EmojiRecord`

## [1.0.0] - 2025-02-05

### Added
- Initial release of Misskey emoji metadata caching and resolution library
- Emoji metadata caching with persistent storage using Isar database (names, URLs, attributes, etc.)
- `EmojiCatalog` abstract interface with `InMemoryEmojiCatalog` and `PersistentEmojiCatalog` implementations
- `EmojiResolver` interface with `MisskeyEmojiResolver` implementation for emoji resolution
- `MisskeyEmojiApi` client for fetching emoji metadata from Misskey servers
- `EmojiStore` interface with `IsarEmojiStore` implementation for persistent metadata storage
- `EmojiSearch` functionality with configurable search options
- Emoji models: `EmojiRecord`, `EmojiDto`, and `EmojiImage` for metadata representation
- Shortcode normalization utilities for consistent emoji handling
- Server database utilities for Isar initialization and management
