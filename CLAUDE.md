# SEVEN

Puzzle aritmético en Flutter (reescritura de una beta de Unity cuyo proyecto se perdió). Cuatro números; se operan de dos en dos hasta que queda uno, que debe ser 7. La puntuación es el tiempo. Modos normal y hardcore. Solo vertical. Objetivo: Google Play, luego App Store.

## Tarea en curso

**Implementar en Flutter el estilo visual aprobado C6 «Negro y lima».** Lee primero [`docs/07-Estilo-C6.md`](docs/07-Estilo-C6.md): tiene los tokens exactos, los componentes, la referencia visual y lo que aún no está diseñado.

Estado del código frente a ese estilo:

- La UI actual (`lib/app/theme.dart`, `lib/app/pixel_widgets.dart`, `lib/features/**`) usa un estilo **descartado**: sprites de la beta (`assets/images/`, `lib/app/assets.dart`) y fuente pixel. Hay que sustituirlo; no adaptarlo.
- La pantalla de juego actual muestra un texto de pista (`hint`) bajo la cabecera. El estilo aprobado **no** lleva barra ni texto de operación en curso.
- La lógica (`packages/seven_engine`, `lib/features/game/game_notifier.dart`) está bien y probada; el rediseño no debería tocarla.
- `test/ui/assets_test.dart` y los golden de `test/ui/goldens/` verifican el estilo viejo: actualizarlos como parte del cambio.
- Solo la pantalla de partida está diseñada. El resto de pantallas y el color del modo hardcore se proponen y se enseñan al autor antes de darlos por buenos.

## Reglas del autor

- **TDD**: test en rojo primero, luego implementación.
- **Verificar visualmente** cualquier cambio de UI antes de presentarlo (golden tests o captura). No presentar diseño sin haberlo visto.
- **Commits solo a nombre del autor**: sin línea `Co-Authored-By`. Commit y push solo cuando lo pida.
- No inventar assets ni reglas de juego: preguntar. Las reglas las dicta el autor (ver `docs/01-PRD.md` §4).
- Responde en español.

## Reglas de juego que suelen entenderse mal

- El orden de los dos números no importa: resta = `|a − b|`, división = `mayor ÷ menor` (exacta, sin cero).
- El resultado se reparte por dígitos en las celdas (`4 × 5 = 20` → `2` y `0`); las celdas vacías se acumulan a la izquierda.
- Normal: los ceros se quedan y «convertir» cambia **todos** los ceros por un dígito 1–9. Si el último número es 0, la partida no termina.
- Hardcore: los ceros se descartan del resultado y no hay «convertir».
- No hay botón de igual: la operación se ejecuta al tocar el segundo número.
- Las reglas viven en `packages/seven_engine` y en su port `supabase/functions/_shared/engine.ts`. Ambos ejecutan `packages/seven_engine/test/vectors/rules.json`: cambia el JSON primero.

## Comandos

```bash
export PATH="/c/Users/migue/flutter/bin:$PATH"   # Flutter no está en el PATH del shell
flutter analyze
flutter test                                      # app: lógica, widgets, golden
flutter test test/ui/visual_test.dart --update-goldens
(cd packages/seven_engine && dart test)           # motor de reglas
flutter run -d chrome                             # sin backend = modo offline
```

Deno (tests del backend): `C:\Users\migue\AppData\Local\Microsoft\WinGet\Packages\DenoLand.Deno_Microsoft.Winget.Source_8wekyb3d8bbwe\deno.exe test -A supabase/tests/engine_vectors_test.ts`

## Pendiente fuera del rediseño

- Backend Supabase escrito (`supabase/`) pero **no desplegado**; sin él no hay ranking.
- Sin probar en dispositivo Android real.
- Hay cambios sin commitear desde el commit inicial de docs.
