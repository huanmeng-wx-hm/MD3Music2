import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/song.dart';

/// 播放历史：只存「歌曲标识 + 展示信息 + 时间」，不存播放链接。
/// 酷狗播放链接带时效，存下来第二天点就是 404；点开时按 songId/hash 重新解析。
class HistoryPlayEntry {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String? remoteSourceId;
  final int playedAt;

  const HistoryPlayEntry({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.remoteSourceId,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'coverUrl': coverUrl,
        'remoteSourceId': remoteSourceId,
        'playedAt': playedAt,
      };

  factory HistoryPlayEntry.fromJson(Map<String, dynamic> j) => HistoryPlayEntry(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        coverUrl: j['coverUrl'] as String?,
        remoteSourceId: j['remoteSourceId'] as String?,
        playedAt: j['playedAt'] as int? ?? 0,
      );
}

class HistoryPlayService {
  HistoryPlayService._();
  static final HistoryPlayService instance = HistoryPlayService._();

  static const _key = 'mini_play_history_v1';
  static const int _max = 200;

  String? _lastRecordedId;

  /// 由界面在每次 build 时喂当前歌曲；同 id 只记一次，切歌才追加。
  Future<void> recordIfChanged(Song? song) async {
    if (song == null || song.id.isEmpty) return;
    if (song.id == _lastRecordedId) return;
    _lastRecordedId = song.id;
    final prefs = await SharedPreferences.getInstance();
    final list = await recent();
    list.removeWhere((e) => e.id == song.id);
    list.insert(
      0,
      HistoryPlayEntry(
        id: song.id,
        title: song.title,
        artist: song.artist,
        coverUrl: song.artworkUri,
        hash: song.remoteSourceId,
        playedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (list.length > _max) list.removeRange(_max, list.length);
    await prefs.setString(
      _key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<HistoryPlayEntry>> recent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <HistoryPlayEntry>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HistoryPlayEntry.fromJson)
          .toList();
    } catch (_) {
      return <HistoryPlayEntry>[];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _lastRecordedId = null;
  }
}
