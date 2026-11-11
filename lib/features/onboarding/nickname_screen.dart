import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/pixel_widgets.dart';
import '../../app/providers.dart';

/// Apodo: 3–12 caracteres, letras y números (mismo criterio que la BD).
final _nicknameRe = RegExp(r'^[A-Za-z0-9]{3,12}$');

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (!_nicknameRe.hasMatch(value)) return;
    setState(() => _saving = true);
    await ref.read(nicknameProvider.notifier).save(value);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text.trim();
    final valid = _nicknameRe.hasMatch(value);
    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu apodo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aparecerá en el ranking mundial. 3–12 letras o números, sin espacios.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 12,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Apodo'),
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: 'GUARDAR',
              height: 52,
              enabled: valid && !_saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}
