# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1-beta] - 2025-01-27

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
- Cross-platform support for iOS and Android
- Integration with `misskey_api_core` for HTTP communication
