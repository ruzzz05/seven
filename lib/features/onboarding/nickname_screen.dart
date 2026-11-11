import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/c6.dart';
import '../../app/providers.dart';
import '../../ui/c6_widgets.dart';

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
      body: C6Page(
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('tu apodo', style: C6.style(28, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'aparecerá en el ranking mundial. 3 a 12 letras o números, sin espacios.',
              style: C6.style(12, color: C6.muted),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _controller,
              maxLength: 12,
              autofocus: true,
              cursorColor: C6.accent,
              style: C6.style(20, weight: FontWeight.w500),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: C6.panel,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(C6.radiusKey),
                  borderSide: const BorderSide(color: C6.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(C6.radiusKey),
                  borderSide: const BorderSide(color: C6.accent),
                ),
              ),
            ),
            const SizedBox(height: 40),
            C6Key(
              height: 60,
              face: valid ? C6.accent : C6.panel,
              faceBorder: valid ? C6.accent : C6.border,
              canto: valid ? C6.accentSide : C6.deep,
              semanticLabel: 'Guardar apodo',
              onTap: valid && !_saving ? _save : null,
              child: Text(
                'guardar',
                style: C6.style(
                  16,
                  weight: FontWeight.w700,
                  color: valid ? C6.onAccent : C6.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
