import '../models/emoji_record.dart';

/// ストアから復元した内容
class EmojiSnapshot {
  const EmojiSnapshot({required this.records, required this.syncedAt});

  /// 保存されていたレコード（[EmojiStore.save]に渡された順序を保持する）
  final List<EmojiRecord> records;

  /// 最後に[EmojiStore.save]が成功したときに渡された時刻
  ///
  /// 一度も保存されていない場合はnull
  final DateTime? syncedAt;
}

/// 永続化用の抽象絵文字ストア
abstract class EmojiStore {
  /// 保存されているレコードと同期時刻を一括で読み込む
  ///
  /// レコードが0件でも同期時刻が記録されていれば返すことで、0件の同期結果と
  /// 未保存の状態を区別する。レコードは[save]に渡された順序を保持する。
  Future<EmojiSnapshot> load();

  /// 渡された一覧で既存のレコードをすべて置き換え、[syncedAt]を記録する
  ///
  /// 空の一覧も有効な同期結果として扱う。[EmojiRecord.name]が重複する場合は、
  /// 後勝ちで重複を除去し、最後の出現位置に配置する。レコードと[syncedAt]は
  /// 同一トランザクションで書き込み、失敗時はいずれも更新しない。
  Future<void> save(List<EmojiRecord> all, {required DateTime syncedAt});

  /// 保持しているレコードと同期時刻をすべて破棄する
  ///
  /// 既存のカタログのインメモリ状態およびTTL判定には影響しない。新しいカタログが
  /// ストアから復元した場合は未保存状態として扱われる。既存のカタログの表示内容も
  /// 直ちに更新する場合は、呼び出し側で`sync(force: true)`を呼ぶ。
  Future<void> clear();

  /// 保持しているレコード件数を返す
  ///
  /// [save]時に重複除去された後、実際に保存されている一意レコード数を返す。
  Future<int> count();

  /// ストアが占有しているストレージのバイト数を返す
  ///
  /// ファイルベースの実装はDB本体と存在するWAL・SHMの論理ファイル長を合算する。
  /// SQLiteでは削除後もVACUUMするまでファイルが縮小しないため、レコードの合計
  /// サイズではなく占有ストレージ量を返す。ファイルを持たない実装はnullを返し、
  /// I/Oエラーはnullに丸めず送出する。
  Future<int?> sizeInBytes();

  /// ストアが使用するリソースをクリーンアップする
  ///
  /// ストアが不要になった時に呼び出す。実装クラスによっては、データベース接続の
  /// クリーンアップなどを行う。
  Future<void> dispose();
}
