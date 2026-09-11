# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The upcoming release migrates persistence from Isar to Drift (SQLite).

### Added

- Added `EmojiSnapshot`, which returns saved records and their synchronization timestamp together
- Added the protected `EmojiCatalogBase.normalizeFetchedRecords(List<EmojiRecord>)` hook, returning the records used by both indexing and `afterFetch`. The default implementation leaves records unchanged.

### Changed

- **Breaking:** Redesigned `EmojiStore`: `loadAll` / `saveAll` are now `load` / `save`, and `clear`, `count`, and `sizeInBytes` were added. Custom `EmojiStore` implementations must implement the new contract.
- **Breaking:** Changed the `EmojiCatalogBase.afterFetch` hook from `afterFetch(List<EmojiRecord>)` to `afterFetch(List<EmojiRecord>, {required DateTime syncedAt})`.
- Marked the `EmojiCatalogBase.beforeSync` and `afterFetch` hooks `@protected`, matching `normalizeFetchedRecords` and `restoreLastSyncedAt`. Subclasses may still override them and call inherited members on `this`; calling them through an instance from outside now reports an analyzer diagnostic. `indexRecords` remains public.
- **Breaking:** Moved store ownership from `IsarEmojiStore.ownsIsar` to `PersistentEmojiCatalog.ownsStore`.
- **Breaking:** Raised the minimum SDK versions to Dart `>=3.10.0 <4.0.0` and Flutter `>=3.38.0`.
- Changed the persistence layer to Drift (SQLite).
- **Behavior change:** `PersistentEmojiCatalog` now deduplicates fetched records by `name` before indexing, using the last value and last occurrence position. If a custom source returns duplicate names, aliases found only on overwritten records no longer resolve immediately after synchronization, matching restored-cache behavior. `InMemoryEmojiCatalog` behavior is unchanged.
- `PersistentEmojiCatalog` now persists the synchronization timestamp, so restarting within the TTL no longer refetches emoji metadata over the network.
- Added a stable eight-digit, 32-bit FNV-1a hash suffix derived from scheme, host, and port to each server database filename, reducing the chance of different servers with colliding server keys sharing a cache file. This finite hash does not guarantee uniqueness.
- When changing the `EmojiDatabase` schema, increment `EmojiDatabase.schemaVersion`. `destructiveFallback` runs only when versions differ; it does not run through `onCreate`.

### Removed

- **Breaking:** Removed `IsarEmojiStore`, `EmojiRecordEntity`, `EmojiRecordEntitySchema`, `toEntity`, `fromEntity`, `openEmojiIsarForServer`, and the ten generated Isar collection and query extensions.

### Migrating custom stores

Custom `EmojiStore` implementations must implement these signatures and semantics:

- `Future<EmojiSnapshot> load()` atomically reads records and their synchronization timestamp. Its `records` is a fixed-length list (elements can be replaced, but the length cannot change), in saved order after deduplication. Return a null `syncedAt` for an unsaved or cleared store; an empty list with a non-null timestamp is a valid saved synchronization result.
- `Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt})` replaces all records and saves the timestamp atomically: on failure, neither changes. Empty lists must also replace existing records and save the timestamp. Duplicate `name` values are last-wins, using the last occurrence's position as well as its value.
- `Future<void> clear()` removes both records and the synchronization timestamp. It does not change an existing catalog's in-memory state or TTL decision; call `sync(force: true)` on that catalog when an immediate refresh is needed.
- `Future<int> count()` returns the number of stored records after deduplication.
- `Future<int?> sizeInBytes()` returns the sum of logical file lengths of the DB and any WAL/SHM files, not the sum of record sizes. Implementations without files return null; I/O errors propagate rather than becoming null.
- `Future<void> dispose()` releases store resources.

## [2.0.0-beta.1] - 2026-08-14

First pre-release of the 2.0.0 line. Contains the breaking changes listed below.

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
