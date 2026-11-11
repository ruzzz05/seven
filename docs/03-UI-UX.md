# UI / UX — SEVEN

Estado: borrador v0.1 · Fecha: 2026-11-11 · Relacionado: [01-PRD.md](01-PRD.md), [04-AppFlow.md](04-AppFlow.md)

## 1. Principios

1. **Un toque claro por acción.** Operación primero, luego dos celdas (según la beta).
2. **El tablero es lo único que importa.** Sin decoración que compita con los números.
3. **Errores silenciosos pero visibles.** Un movimiento inválido no cambia nada y se indica con una vibración corta y un destello rojo en la celda.
4. **Modo siempre visible.** El color de la pantalla de juego indica el modo.
5. **Sin texto innecesario.** Todo en español, etiquetas cortas.

## 2. Paleta (tokens)

Definir en `lib/app/theme/tokens.dart`. Valores provisionales; ajustar tras prueba visual.

| Token | Normal | Hardcore | Uso |
|-------|--------|----------|-----|
| `bg` | `#1B2A3A` | `#1A0F14` | Fondo |
| `surface` | `#243A4F` | `#2E1A22` | Tarjetas y paneles |
| `cell` | `#F4F1EA` | `#F4F1EA` | Celda con número |
| `cellEmpty` | `#33495F` | `#4A2A35` | Celda vacía (`-`) |
| `accent` | `#F2B705` | `#E0457B` | Botón activo, victoria |
| `op` | `#5BC0EB` | `#FF8A5B` | Botones de operación |
| `danger` | `#E63946` | `#E63946` | Movimiento inválido, derrota |
| `ok` | `#2EC4B6` | `#2EC4B6` | Victoria |
| `text` | `#F4F1EA` | `#F4F1EA` | Texto principal |

Fuente: Retro Gaming (de la beta) para títulos y tablero; LiberationSans para textos. Licencia de la fuente a verificar antes de publicar.

## 3. Componentes

| Componente | Descripción |
|------------|-------------|
| `CellTile` | Cuadrado con dígito, vacío (`-`) o seleccionado. Tamaño mínimo 64 dp. |
| `OpButton` | Botón con `+ − × ÷`. Estado: normal, activo (esperando celdas), deshabilitado. |
| `ConvertButton` | Visible en Normal. Deshabilitado si no hay 0. |
| `DigitPad` | Panel 1–9 en modal inferior. Solo se abre con Convertir. |
| `TimerLabel` | `mm:ss.cs`, actualiza cada 10 ms. |
| `BoardRow` | Fila de 4 `CellTile`, alineada a la derecha. |
| `RankRow` | Posición, apodo, tiempo. Resalta al jugador. |
| `ModeTabs` | Normal / Hardcore en ranking. |

## 4. Pantallas

### 4.1 Inicio (`/`)

```
┌──────────────────────────┐
│         SEVEN            │
│                          │
│   [   JUGAR NORMAL   ]   │
│   [   JUGAR HARDCORE ]   │
│                          │
│   [ Ranking ] [ Ayuda ]  │
│                          │
│   [ Salir ]              │
└──────────────────────────┘
```

- Primer arranque: abre Nickname antes.
- "Salir" solo en Android (botón atrás lo cubre).

### 4.2 Apodo (`/onboarding`)

- Campo de texto 3–12 caracteres, letras y números.
- Botón "Guardar". Validación en tiempo real.
- Se puede omitir: el ranking pide apodo en la victoria si falta.

### 4.3 Juego (`/game/:mode`)

```
┌──────────────────────────┐
│ ←      NORMAL    00:12.4 │   barra superior: volver, modo, cronómetro
│                          │
│  [ - ][ - ][ 3 ][ 5 ]    │   BoardRow
│                          │
│  [ + ] [ − ] [ × ] [ ÷ ] │   OpButton ×4
│                          │
│  [ CONVERTIR ]           │   solo Normal
│                          │
│  [ Reiniciar ]           │
└──────────────────────────┘
```

Flujo de selección:
1. Tocar operación → botón activo, mensaje "Elige 2 números" bajo el tablero.
2. Tocar celda 1 → se resalta (borde accent).
3. Tocar celda 2 → se ejecuta automáticamente (no hay botón de igual). Si es inválido: shake + destello `danger` en ambas celdas, la selección se borra.
4. Tocar la misma operación de nuevo, o fuera del tablero → cancela.
5. Solo se puede tocar celdas con número. Las vacías no responden.

Convertir (Normal):
- Pulsar CONVERTIR → se abre `DigitPad` (1–9) en modal inferior.
- Al elegir dígito → todos los 0 cambian con animación de 200 ms y se cierra el panel.
- Mientras no haya 0, el botón está deshabilitado con tooltip "No hay ceros".

Estados visuales:
- **Último número 0 (Normal):** la celda 0 parpadea y CONVERTIR se pone en `accent`. La partida no termina.
- **Victoria:** transición a `/result/win`.
- **Derrota:** transición a `/result/lose`.

### 4.4 Resultado (`/result/:outcome`)

Victoria:
```
        ¡SIETE!
     tiempo  00:12.43
     mejor personal  00:11.90
     posición mundial  #— (enviando…)
   [ REINTENTAR ]   [ RANKING ]   [ MENÚ ]
```
- Al abrir, enviar partida al servidor. Si está offline, muestra "Guardado. Se enviará al volver la conexión."

Derrota:
```
        FIN
     último número: 5
   [ REINTENTAR ]   [ MENÚ ]
```

### 4.5 Ranking (`/ranking`)

- Tabs Normal / Hardcore.
- Lista top 100 con paginación.
- Fila propia fijada abajo si no está en el top.
- Pull-to-refresh.

### 4.6 Ayuda (`/help`)

- Reglas en 5 bloques con iconos:
  1. Objetivo: deja un solo número y que sea 7.
  2. Operaciones y orden de toque.
  3. Negativos y divisiones no exactas no se permiten.
  4. Normal: Convertir cambia los 0.
  5. Hardcore: sin ceros ni Convertir.
- Texto final pendiente de confirmar (ver supuestos PRD §9.9).

## 5. Responsive y accesibilidad

- Diseño base: 360×800 dp. Tablero y botones escalan con `LayoutBuilder`.
- Tamaño de texto del sistema: el tablero no se rompe hasta escala 1,3.
- Contraste mínimo 4,5:1 en texto y 3:1 en elementos de estado.
- Semántica: cada celda con etiqueta "Celda 3, valor 5" o "Celda vacía".
- Modo oscuro: es el único tema en v1 (la beta lo era).

## 6. Microinteracciones

| Evento | Respuesta |
|--------|-----------|
| Operación válida | Celdas cambian con fade 150 ms |
| Operación inválida | Shake 120 ms + vibración ligera |
| Victoria | Destello `ok` 400 ms, cronómetro se detiene |
| Derrota | Destello `danger` |
| Cambio de modo | Transición de color 300 ms |

Sin sonido en v1.

## 7. Estados vacíos y errores

- Ranking vacío: "Aún no hay tiempos. ¡Sé el primero!"
- Sin red en ranking: "Sin conexión. Reintentar."
- Error de servidor al enviar: mantener en cola y mostrar "Pendiente de envío".
