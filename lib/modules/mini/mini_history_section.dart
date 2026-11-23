import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import 'history_play_service.dart';

/// 挂在搜索页顶部：自动记录当前播放的歌，并列出最近播放。
/// 只依赖 PlayerProvider.currentSong，不碰播放链路。
class MiniHistorySection extends StatefulWidget {
  const MiniHistorySection({super.key});

  @override
  State<MiniHistorySection> createState() => _MiniHistorySectionState();
}

class _MiniHistorySectionState extends State<MiniHistorySection> {
  Future<List<HistoryPlayEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = HistoryPlayService.instance.recent();
  }

  void _refresh() {
    setState(() {
      _future = HistoryPlayService.instance.recent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<PlayerProvider>().currentSong;
    // build 里顺手记一次；service 内部按 id 去重，不会每帧写盘。
    HistoryPlayService.instance.recordIfChanged(current);

    return FutureBuilder<List<HistoryPlayEntry>>(
      future: _future,
      builder: (context, snap) {
        final items = snap.data ?? const <HistoryPlayEntry>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('最近播放', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await HistoryPlayService.instance.clear();
                      if (mounted) _refresh();
                    },
                    child: const Text('清空'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length > 20 ? 20 : items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = items[i];
                  return SizedBox(
                    width: 150,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 2),
                            Text(e.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
