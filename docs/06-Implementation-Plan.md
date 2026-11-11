# Implementation Plan — SEVEN

Estado: borrador v0.1 · Fecha: 2026-11-11 · Relacionado: [01-PRD.md](01-PRD.md), [02-TRD.md](02-TRD.md), [05-Backend-Schema.md](05-Backend-Schema.md)

Estimación: 5–7 semanas a tiempo parcial (≈ 10–15 h/semana). Cada fase termina con algo usable.

## Fase 0 — Preparación (2–3 días)

- [ ] Confirmar supuestos PRD §9 (orientación, cronómetro, Convertir, `−`/`÷`, Hardcore 0, sin movimientos, Reinicio, Ayuda, sin sonido).
- [ ] Crear repo git (`seven/`) con `.gitignore` de Flutter.
- [ ] Crear proyecto Flutter con `flutter create --org <tu.dominio> seven` (elegir `applicationId` definitivo).
- [ ] Crear paquete `packages/seven_engine` (`dart create -t package`).
- [ ] Crear proyecto Supabase y `supabase init`.
- [ ] Configurar GitHub Actions: `flutter analyze`, `flutter test`.
- [ ] Verificar licencia de la fuente Retro Gaming para uso comercial.

**Hecho cuando:** `flutter run` abre una pantalla vacía en emulador y CI está en verde.

## Fase 1 — Motor de reglas (1 semana)

- [ ] Modelar `Board`, `Move`, `Op`, `GameMode`, `Outcome` (sección 3 del TRD).
- [ ] Implementar `apply` con los 7 pasos de `OpMove` y `ConvertMove`.
- [ ] Implementar `outcome` y `canConvert`.
- [ ] Escribir `rules.json` con todos los casos obligatorios (TRD §4).
- [ ] Runner de vectores en Dart.
- [ ] Revisar cada caso contra la beta jugándola en paralelo.

**Hecho cuando:** `seven_engine` tiene ≥ 95 % de cobertura y todos los vectores pasan. Partidas simuladas de 1000 tableros aleatorios terminan sin excepciones.

## Fase 2 — Juego local (1,5 semanas)

- [ ] Tema y tokens (UI-UX §2) para modo Normal y Hardcore.
- [ ] Pantalla de inicio y navegación con `go_router` (sin backend todavía).
- [ ] `GameController` (Riverpod) que usa `seven_engine`.
- [ ] Widgets `CellTile`, `BoardRow`, `OpButton`, `ConvertButton`, `DigitPad`, `TimerLabel`.
- [ ] Flujo de selección (operación → 2 celdas → cancelar).
- [ ] Animaciones: fade, shake, destellos.
- [ ] Pantallas Victoria y Derrota (sin envío).
- [ ] Ayuda con texto provisional.
- [ ] Mejor tiempo local en `shared_preferences`.

**Hecho cuando:** se puede jugar una partida completa en ambos modos en emulador, con cronómetro correcto y mejor tiempo guardado.

## Fase 3 — Backend y ranking (1,5 semanas)

- [ ] Aplicar migración de `05-Backend-Schema.md`.
- [ ] Integrar `supabase_flutter` y `signInAnonymously` al arrancar.
- [ ] Onboarding de apodo (validación + `profiles`).
- [ ] Edge Function `start-run`. Cliente la llama al pulsar Jugar.
- [ ] Edge Function `finish-run` con `_shared/engine.ts` (port del motor).
- [ ] Ejecutar `rules.json` también en Deno (`supabase/tests`).
- [ ] Pantalla de Ranking con tabs y paginación.
- [ ] Cola offline (`pending_runs`) con reintentos.
- [ ] Mostrar posición tras victoria.

**Hecho cuando:** una victoria aparece en el ranking global desde dos dispositivos distintos; una partida manipulada (movimiento falso enviado a mano) es rechazada.

## Fase 4 — Pulido y pruebas (1 semana)

- [ ] Test de widget de pantalla de juego (Normal muestra Convertir; Hardcore no).
- [ ] Test de integración de partida completa en ambos modos.
- [ ] Pruebas en 3 dispositivos Android reales (distintos tamaños).
- [ ] Revisión de accesibilidad: tamaños de texto, contraste, etiquetas semánticas.
- [ ] Textos finales en español (revisión ortográfica).
- [ ] Icono adaptativo, splash screen, nombre de la app.
- [ ] Pantalla de Ayuda con texto final.
- [ ] Revisar rendimiento: sin jank en animaciones (DevTools).

**Hecho cuando:** sin crashes en 20 partidas seguidas por dispositivo; checklist de accesibilidad completo.

## Fase 5 — Publicación en Google Play (1 semana)

- [ ] Cuenta Google Play Console (pago único 25 USD).
- [ ] Página de política de privacidad pública (texto corto: sin datos personales, sesión anónima de Supabase).
- [ ] Formulario de seguridad de datos y clasificación de contenido en Play Console.
- [ ] Generar keystore de subida, guardar en gestor de contraseñas y copia offline.
- [ ] Build AAB: `flutter build appbundle --release`.
- [ ] Subir a pista de pruebas internas (testers cerrados ≥ 12 si la cuenta es personal nueva; verificar requisito vigente).
- [ ] Capturas de pantalla (teléfono, mínimo 2), icono 512×512, gráfico de funciones 1024×500.
- [ ] Descripción en español.
- [ ] Enviar a producción tras pruebas internas.

**Hecho cuando:** la app está publicada en Google Play o en revisión.

## Fase 6 — iOS / App Store (posterior)

- [ ] Cuenta Apple Developer (99 USD/año).
- [ ] Acceso a Mac para compilar y firmar (o CI con macOS runner).
- [ ] Configurar bundle ID, perfiles y capacidades.
- [ ] Probar con TestFlight.
- [ ] Revisión de App Store (capturas para iPhone, política de privacidad, clasificación de edad).

## Fase 7 — Post-lanzamiento (continuo)

- Revisar métricas (PRD §7).
- Corregir reglas si la comunidad detecta diferencias con la beta.
- Sonido, idiomas y cuentas vinculables como iteraciones posteriores.

## Riesgos de ejecución

| Riesgo | Señal | Respuesta |
|--------|-------|-----------|
| Reglas no coinciden con la beta | Jugadores reportan casos raros | Añadir vectores; corregir motor y servidor a la vez |
| Divergencia Dart / TypeScript | Vectores fallan en uno de los dos | Un solo `rules.json` como fuente; CI ejecuta ambos |
| Tiempos falsos en ranking | Top con tiempos imposibles | Subir `min_time`; revisar `moves` manualmente |
| Requisito de testers en Play para cuentas nuevas | Bloqueo al publicar en producción | Planificar 12+ testers con antelación |

## Próximo paso

Confirmar supuestos (PRD §9) y decidir `applicationId`. Después empezar por Fase 0 y Fase 1.
