# SEVEN

Puzzle aritmético en español. Cuatro números, operaciones entre dos de ellos, y un único número final que debe ser **7**. Tu puntuación es el tiempo: cuanto menos, mejor.

Versión Flutter de la beta de Unity. Modos **Normal** (con conversión de ceros) y **Hardcore** (sin ceros).

Documentación de diseño: [`docs/`](docs/) (PRD, TRD, UI-UX, AppFlow, esquema de backend, plan de implementación).

## Requisitos

- Flutter 3.47+ (canal stable) y Dart 3.13+
- Para Android: Android SDK (ya instalado en esta máquina)
- Para el backend (opcional): CLI de Supabase y una cuenta en supabase.com
- Para tests de backend: Deno 2.x

## Ejecutar

```bash
flutter pub get
flutter run -d chrome          # web, sin backend (modo offline)
flutter run -d <dispositivo>   # Android
```

Sin backend la app funciona completa, pero no hay ranking mundial.

## Tests

```bash
# Motor de reglas (Dart puro)
cd packages/seven_engine && dart test && cd -

# App Flutter (lógica de juego y widgets)
flutter test

# Edge Functions: mismos vectores de reglas que Dart
deno test -A supabase/tests/engine_vectors_test.ts

# Análisis estático
flutter analyze
```

Los vectores de reglas viven en `packages/seven_engine/test/vectors/rules.json`. Dart y TypeScript los ejecutan. Si cambias una regla, cambia el JSON primero y haz que fallen los dos lados.

## Backend (Supabase)

1. Crear proyecto en supabase.com. Anotar **Project URL** y **publishable key** (Settings → API).
2. Enlazar y aplicar la migración:
   ```bash
   supabase link --project-ref <REF>
   supabase db push
   ```
3. Desplegar las funciones:
   ```bash
   supabase functions deploy start-run
   supabase functions deploy finish-run
   ```
   Las funciones usan `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY`, que Supabase inyecta automáticamente. No hay que configurar secretos extra.
4. Ejecutar la app con las credenciales del cliente (nunca la service role):
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://<REF>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<publishable-key>
   ```

Las partidas ganadas se validan en `finish-run`: se reproducen los movimientos con el motor y se comprueba el tiempo. Las rechazadas no entran al ranking.

## Estructura

```
lib/
  app/          router, tema (colores por modo), providers
  data/         almacenamiento local, backend de ranking (Supabase)
  features/     game, result, ranking, help, home, onboarding
packages/
  seven_engine/   reglas puras en Dart (con tests y vectores)
supabase/
  migrations/     esquema, RLS, funciones de ranking
  functions/      start-run, finish-run, _shared (port del motor)
  tests/          vectores ejecutados en Deno
docs/             documentación de diseño
```

## Reglas (resumen)

- Tablero de 4 celdas alineadas a la derecha. Vacías = `-`.
- Operación: primero el botón (`+ − × ÷`), luego dos números. Se ejecuta sola al tocar el segundo.
- El orden de los dos números no cambia el resultado: `3 − 5` y `5 − 3` dan 2. Lo mismo en `÷` (`mayor ÷ menor`).
- División no exacta o entre cero: no permitida, la partida sigue.
- Normal: los ceros se conservan. CONVERTIR cambia todos los ceros por el número que elijas.
- Hardcore: sin ceros ni CONVERTIR. Un resultado que sea solo 0 no se permite.
- Ganas si el último número es 7. Pierdes si es otro número.
- El cronómetro empieza en tu primer toque.

## Estado

- Motor de reglas, juego, resultados, ranking y ayuda: implementados y con tests.
- Backend: migración y Edge Functions escritas y verificadas por tipos y vectores. No desplegadas (requiere tu proyecto de Supabase).
- Sin audio (igual que la beta).
- Assets gráficos de la beta: retirados del repo (no se usan en el estilo C6).
- Sin sprite en la beta: el botón ÷ (dibujado con bloques pixel), los botones de texto (Jugar, Ranking, Reintentar, Menú) que usan `PixelButton` con los colores de la beta.
- Colores del modo Hardcore: la beta cambiaba el color del menú; el valor exacto no está en los assets, así que el tono actual es provisional.
- Publicación en Google Play / App Store: pendiente (requiere tus cuentas y firma).
