import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seven_engine/seven_engine.dart';

import '../../app/c6.dart';
import '../../app/providers.dart';
import '../../data/ranking_backend.dart';
import '../../ui/c6_widgets.dart';
import '../common/format.dart';

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<RankEntry>, GameMode>((ref, mode) async {
      final backend = ref.watch(rankingBackendProvider);
      if (backend == null) throw StateError('offline');
      return backend.leaderboard(mode);
    });

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  GameMode _mode = GameMode.normal;

  @override
  Widget build(BuildContext context) {
    final backendOn = ref.watch(rankingBackendProvider) != null;

    Widget body;
    if (!backendOn) {
      body = Center(
        child: Text(
          'ranking no disponible sin conexión configurada',
          textAlign: TextAlign.center,
          style: C6.style(12, color: C6.muted),
        ),
      );
    } else {
      body = ref
          .watch(leaderboardProvider(_mode))
          .when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: C6.accent),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('sin conexión', style: C6.style(13)),
                  const SizedBox(height: 14),
                  C6Key(
                    width: 180,
                    height: 48,
                    onTap: () => ref.invalidate(leaderboardProvider(_mode)),
                    child: Text(
                      'reintentar',
                      style: C6.style(13, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            data: (rows) => rows.isEmpty
                ? Center(
                    child: Text(
                      'aún no hay tiempos. sé el primero',
                      textAlign: TextAlign.center,
                      style: C6.style(12, color: C6.muted),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: C6.border,
                    ),
                    itemBuilder: (_, k) {
                      final r = rows[k];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${r.position}',
                                style: C6.style(
                                  15,
                                  weight: FontWeight.w700,
                                  color: C6.accent,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(r.nickname, style: C6.style(15)),
                            ),
                            Text(
                              formatMs(r.timeMs),
                              style: C6.style(15, color: C6.text),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 46, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  C6Key(
                    width: 44,
                    height: 44,
                    semanticLabel: 'Volver',
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.chevron_left, color: C6.text),
                  ),
                  const Spacer(),
                  Text('ranking', style: C6.style(16)),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  for (final m in GameMode.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: m == GameMode.normal ? C6.gap : 0,
                        ),
                        child: C6Key(
                          height: 44,
                          active: _mode == m,
                          semanticLabel: 'Modo ${m.name}',
                          onTap: () => setState(() => _mode = m),
                          child: Text(
                            m.name,
                            style: C6.style(
                              13,
                              weight: FontWeight.w500,
                              color: _mode == m ? C6.onAccent : C6.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
