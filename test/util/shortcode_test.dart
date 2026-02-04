import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_emoji/src/util/shortcode.dart';

void main() {
  group('normalizeShortcode', () {
    test('コロンで囲まれたショートコードを正規化', () {
      expect(normalizeShortcode(':example:'), equals('example'));
    });

    test('コロンなしのショートコードをそのまま正規化', () {
      expect(normalizeShortcode('example'), equals('example'));
    });

    test('大文字を小文字に変換', () {
      expect(normalizeShortcode(':Example:'), equals('example'));
      expect(normalizeShortcode('EXAMPLE'), equals('example'));
      expect(normalizeShortcode(':MixedCase:'), equals('mixedcase'));
    });

    test('前後の空白を削除', () {
      expect(normalizeShortcode('  example  '), equals('example'));
      expect(normalizeShortcode('  :example:  '), equals('example'));
      expect(normalizeShortcode('\t:example:\n'), equals('example'));
    });

    test('絵文字変化セレクタ（U+FE0F）を削除', () {
      expect(normalizeShortcode(':exa\uFE0Fmple:'), equals('example'));
      expect(normalizeShortcode('test\uFE0F'), equals('test'));
    });

    test('空文字列の処理', () {
      expect(normalizeShortcode(''), equals(''));
      expect(normalizeShortcode('::'), equals(''));
      expect(normalizeShortcode('  '), equals(''));
    });

    test('特殊文字を含むショートコード', () {
      expect(normalizeShortcode(':test_emoji:'), equals('test_emoji'));
      expect(normalizeShortcode(':emoji-123:'), equals('emoji-123'));
      expect(normalizeShortcode(':emoji.test:'), equals('emoji.test'));
    });

    test('片方だけコロンがある場合', () {
      expect(normalizeShortcode(':example'), equals(':example'));
      expect(normalizeShortcode('example:'), equals('example:'));
    });

    test('複数のコロンを含む場合', () {
      expect(normalizeShortcode('::example::'), equals(':example:'));
    });

    test('日本語を含むショートコード', () {
      expect(normalizeShortcode(':テスト:'), equals('テスト'));
      expect(normalizeShortcode('日本語'), equals('日本語'));
    });

    test('複合的なケース', () {
      expect(
        normalizeShortcode('  :Test_Emoji\uFE0F-123:  '),
        equals('test_emoji-123'),
      );
    });
  });
}
