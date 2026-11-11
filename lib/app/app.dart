import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class SevenApp extends ConsumerWidget {
  const SevenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SEVEN',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(SevenPalette.normal),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
