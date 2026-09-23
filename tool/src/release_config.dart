import 'release_project.dart';

/// Release settings for this repository.
///
/// `release_project.dart` is shared verbatim across the packages that use this
/// tool. Everything specific to this repository belongs here instead.
const releaseConfig = ReleaseConfig(
  versionReferencePaths: <String>['README.md', 'README.ja.md'],
);
