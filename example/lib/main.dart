import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

import 'app.dart';

void main() {
  // 現在のisolate内でDrift全体の診断フラグを変更し、複数サーバーのキャッシュを許可する。
  suppressMultipleDatabaseWarning();
  runApp(const App());
}
