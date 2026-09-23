import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/cache/drift/connection/unsupported.dart'
    as unsupported;
import 'package:misskey_emoji/src/cache/drift/connection/web.dart' as web;

void main() {
  test('unsupportedのopenStoreはFuture合成でUnsupportedErrorを返す', () async {
    final error = await _captureError(
      unsupported.openStore(directory: 'cache', databaseName: 'emoji'),
    );

    expect(error, isA<UnsupportedError>());
  });

  test('webのopenStoreはFuture合成でUnimplementedErrorを返す', () async {
    final error = await _captureError(
      web.openStore(directory: 'cache', databaseName: 'emoji'),
    );

    expect(error, isA<UnimplementedError>());
  });
}

Future<Object?> _captureError(Future<Object?> future) => future
    .then<Object?>((_) => fail('エラーになるはずです'))
    .catchError((Object error) => error);
