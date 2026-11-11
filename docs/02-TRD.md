# TRD — SEVEN (versión Flutter)

Estado: borrador v0.1 · Fecha: 2026-11-11 · Relacionado: [01-PRD.md](01-PRD.md)

## 1. Stack

| Capa | Tecnología | Motivo |
|------|-----------|--------|
| App | Flutter (stable actual), Dart 3.x | Un código para Android e iOS |
| Estado | Riverpod 2.x (`flutter_riverpod`) | Testeable, sin BuildContext en lógica |
| Navegación | `go_router` | Rutas declarativas, deep links futuros |
| Motor de reglas | Paquete Dart puro `seven_engine` | Sin dependencias de Flutter; tests unitarios rápidos |
| Persistencia local | `shared_preferences` (mejor tiempo, apodo, sesión) | Datos pequeños |
| Cola offline | `hive_ce` o JSON en archivo | Reintento de envíos de ranking |
| Backend | Supabase: Postgres, Auth anónima, Edge Functions (TypeScript/Deno), RLS | Ranking y validación sin servidor propio |
| Analítica | Ninguna en v1 | Privacidad |
| Crash reporting | Firebase Crashlytics o Sentry (decidir antes de fase 1) | Estabilidad |
| CI/CD | GitHub Actions: `flutter test`, build AAB | Calidad y release reproducible |

## 2. Arquitectura

```
seven/                       (app Flutter)
  lib/
    app/                     router, tema, DI (providers)
    features/
      home/
      game/                  pantalla, widgets, controlador
      result/                victoria / derrota
      ranking/
      help/
      onboarding/            apodo
    data/
      local/                 prefs, cola offline
      remote/                cliente Supabase, DTOs
  packages/
    seven_engine/            reglas puras (sin Flutter)
      lib/src/
        board.dart           estado del tablero
        operations.dart      + − × ÷ y validación
        rules.dart           victoria, derrota, conversión
        game_mode.dart       normal | hardcore
        moves.dart           tipos de movimiento serializables
      test/
        engine_test.dart
        vectors/             casos compartidos con el servidor (JSON)
supabase/
  functions/
    start-run/index.ts
    finish-run/index.ts
    _shared/engine.ts        port del motor (mismo JSON de vectores)
  migrations/                SQL (ver 05-Backend-Schema.md)
  tests/                     tests de vectores
```

Regla de oro: **las reglas viven solo en `seven_engine`**. La UI no calcula nada del tablero.

## 3. Modelo de datos del motor

```dart
enum GameMode { normal, hardcore }

class Board {
  final List<int?> cells; // length 4; null = vacío
  // Invariante: los null están a la izquierda; no hay null entre valores.
}

sealed class Move {}
class OpMove extends Move { final Op op; final int i; final int j; } // i < j, índices de celda
class ConvertMove extends Move { final int digit; }                  // 1..9; solo Normal

enum Op { add, sub, mul, div }

enum Outcome { ongoing, won, lost }
```

Funciones puras:

```dart
MoveResult apply(Board b, GameMode mode, Move m);   // ok | invalid(reason)
Outcome outcome(Board b, GameMode mode);
bool canConvert(Board b, GameMode mode);            // Normal && hay un 0
```

Algoritmo de `OpMove(op, i, j)` con `i < j` sobre celdas no nulas:

1. `a = cells[i]`, `b = cells[j]`.
2. `r` según `op`. Si `r < 0`, o `op == div` y (`b == 0` o `a % b != 0`) → `invalid`.
3. `digits = r.toString().split('')`. Si `mode == hardcore`, eliminar `'0'`.
4. Si `digits` está vacío → `invalid` (solo posible en hardcore con `r == 0`).
5. `cells[i] = null; cells[j] = null`.
6. Escribir `digits[0]` en `cells[i]`. Si hay `digits[1]`, escribirlo en `cells[j]`.
7. Alinear a la derecha: concatenar no nulos en orden y rellenar con `null` a la izquierda.

Nota: un resultado de 2 dígitos siempre cabe en `i` y `j` (máximo `9 × 9 = 81`).

Algoritmo de `ConvertMove(d)`:
- Requiere `mode == normal` y al menos un 0.
- Reemplazar todos los `0` por `d`.

## 4. Pruebas de reglas

Tabla de vectores en `packages/seven_engine/test/vectors/rules.json`. Cada caso:

```json
{ "name": "mul 3x5 -> 15", "mode": "normal",
  "board": [null, null, 3, 5], "move": {"op":"mul","i":2,"j":3},
  "expect": {"result":"ok", "board": [null, null, 1, 5]} }
```

Casos obligatorios:
- Sección 4.2 del PRD (ejemplos normativos).
- Negativos, división no exacta, división por cero → `invalid`, tablero sin cambios.
- Normal `4×5` → `[null,null,2,0]`; Hardcore `4×5` → `[null,null,null,2]`.
- Hardcore `3−3` → `invalid`.
- Convert: todos los ceros cambian; Hardcore → `invalid`.
- `outcome`: único 7 → won; único 5 → lost; único 0 Normal → ongoing; único 0 Hardcore imposible.
- Sin movimientos válidos → lost.

Los mismos JSON los ejecutan Dart (`flutter test`) y Deno (`supabase/tests`). Si difieren, el ranking falla: es el control de integridad principal.

## 5. Backend (Supabase)

### 5.1 Servicios

- **Auth:** `signInAnonymously()` al primer arranque. El `user.id` es el jugador. Opcional: vincular email más adelante (`linkIdentity`).
- **Postgres:** tablas en `05-Backend-Schema.md`.
- **Edge Functions:**
  - `POST /start-run` → crea fila `runs` con `status='started'`, genera tablero inicial **en el servidor** (4 dígitos 1–9) y devuelve `run_id`, `board`, `mode`.
  - `POST /finish-run` → recibe `run_id`, `moves[]`, `time_ms`. Reproduce los movimientos con `_shared/engine.ts`, comprueba victoria y plausibilidad del tiempo, y guarda `status='valid'` o `'rejected'`.
- **RPC:** `get_leaderboard(mode, limit, offset)` y `get_my_rank(mode)`.

### 5.2 Por qué el tablero inicial lo genera el servidor

Si el cliente generara el tablero, podría elegir uno fácil. El servidor reparte el tablero; el cliente solo juega. El mismo `run_id` no puede reutilizarse.

### 5.3 Validación del tiempo

- `time_ms` debe ser ≥ `(finished_at - started_at)` menos una tolerancia (p. ej. 2 000 ms) para latencia.
- `time_ms` debe ser ≥ un mínimo configurable por modo (p. ej. 3 000 ms). Ajustar con datos reales.
- Partidas que no cumplen → `rejected`, no aparecen en ranking.

### 5.4 Seguridad

- RLS activo en todas las tablas.
- Clientes: `SELECT` de su propio perfil y de sus runs; `INSERT/UPDATE` de `runs` solo vía Edge Functions con service role.
- Leaderboard: vista pública de solo `nickname`, `mode`, `time_ms`.
- Clave `anon` en la app; service role solo en servidor. Nunca en el cliente.
- Límite de peticiones por IP y por usuario en Edge Functions (rate limit simple con tabla o cabecera).

## 6. Persistencia local

| Clave | Contenido |
|-------|-----------|
| `nickname` | string |
| `best_ms.normal`, `best_ms.hardcore` | int |
| `pending_runs` | lista JSON de partidas no enviadas |
| `onboarding_done` | bool |

Sin datos de partida en curso: si la app se cierra durante una partida, esta se pierde (decisión v1).

## 7. Calidad

- Cobertura de `seven_engine` ≥ 95 %.
- Test de widget para pantalla de juego (modo, botones deshabilitados, panel 1–9 visible solo con 0 en Normal).
- Test de integración: partida completa en modo normal y hardcore en emulador.
- Linter: `very_good_analysis` o `flutter_lints` estricto.

## 8. Build y release

- Android: `applicationId` propio (decidir; no reutilizar el de la beta si la app es nueva). Firma con Play App Signing. Formato AAB.
- Versionado: `version: 1.0.0+1` en `pubspec.yaml`.
- Google Play Console: cuenta de desarrollador (pago único de 25 USD).
- iOS (fase 2): cuenta Apple Developer (99 USD/año), Mac para compilar y firmar, TestFlight.

## 9. Dependencias iniciales (aprox.)

```
flutter_riverpod, go_router, shared_preferences, supabase_flutter, hive_ce (opcional), equatable
dev: flutter_test, mocktail, very_good_analysis
```

Versiones exactas se fijan al crear el proyecto (`flutter pub add`).
