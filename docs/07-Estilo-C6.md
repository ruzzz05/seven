# Estilo visual aprobado: C6 «Negro y lima»

Estado: **aprobado por el autor** el 2026-11-11 · Sustituye a `03-UI-UX.md` en todo lo visual (paleta, tipografía, componentes). `03-UI-UX.md` sigue valiendo para flujos y accesibilidad.

Referencia visual exacta de la pantalla de partida:

- Captura: [`design/c6-partida.png`](design/c6-partida.png) (390 × 844)
- HTML/CSS fuente de esa captura: [`design/c6-partida.html`](design/c6-partida.html) — todas las medidas de este documento salen de ahí. En caso de duda, manda el HTML.
- Canvas con todas las exploraciones: https://claude.ai/artifact/3Y9CbJdK3RcSnbDt3964V7 (página «H1 · 8 paletas», artboard C6)

## 1. Cómo se llegó aquí (para entender la idea)

El autor rechazó, en este orden: los sprites de la beta de Unity, el pixel art, y diez estilos temáticos (brutalista, synthwave, naipes…). Lo que aprobó es la combinación de dos propuestas:

- De la «Tinta y teclas»: **simpleza y estructura**. Pocas cosas en pantalla, cronómetro grande, meta visible, teclas con volumen.
- De la «Editor de código»: **el lenguaje visual**. Fondo oscuro, fuente monoespaciada, fichas redondeadas con borde fino, teclas con canto inferior. **Sin nada que parezca código** (ni pestañas, ni números de línea, ni barra de estado, ni sintaxis).

Decisiones explícitas del autor:

1. **Simple y limpio.** Si un elemento no es necesario para jugar, no va.
2. **Sin barra de operación.** Se eliminó el panel que mostraba `3 + ▮` con lo que vas pulsando. No reintroducirlo, ni como texto de ayuda permanente.
3. **Solo vertical.** Ya está bloqueado en `lib/main.dart` y en `AndroidManifest.xml`.
4. **Un solo acento.** El lima se usa para lo activo/seleccionado y para la meta. Nada más lleva color salvo el rojo del reinicio.
5. No usar los sprites de la beta (`assets/images/`) ni la fuente pixel en esta UI.

## 2. Tokens

### Color

| Token | Hex | Uso |
|-------|-----|-----|
| `bg` | `#0A0A0A` | Fondo de todas las pantallas |
| `panel` | `#161616` | Cara de fichas y teclas |
| `border` | `#2C2C2C` | Borde de 1 px de fichas, teclas, píldoras; trazo discontinuo de la celda vacía |
| `deep` | `#000000` | Canto inferior de fichas y teclas (el «volumen») |
| `text` | `#F5F5F5` | Texto principal, dígitos, cronómetro |
| `muted` | `#8A8A8A` | Etiquetas pequeñas, guion de la celda vacía |
| `accent` | `#D4FF3A` | Ficha seleccionada, operación activa, insignia de meta, puntos de «quedan» |
| `accentSide` | `#8FB01A` | Canto inferior de lo que va en `accent` |
| `onAccent` | `#0A0A0A` | Texto sobre `accent` |
| `ring` | `#D4FF3A` al 18 % | Halo de 4 px alrededor de la ficha seleccionada |
| `cta` | `#F5F5F5` | Botón «convertir ceros» |
| `ctaSide` | `#A8A8A8` | Canto inferior del CTA |
| `onCta` | `#0A0A0A` | Texto del CTA |
| `danger` | `#FF6B6B` | Icono de reiniciar (solo el icono) |

### Tipografía

Una sola familia: **JetBrains Mono** (ya en `assets/fonts/`, registrada en `pubspec.yaml` como `JetBrainsMono`, pesos 400/500/700; licencia OFL en `design/JetBrainsMono-OFL.txt`).

| Rol | Tamaño | Peso | Notas |
|-----|--------|------|-------|
| Cronómetro | 52 | 700 | `height: 1`, `letterSpacing: -1`, cifras tabulares |
| Dígito de ficha | 44 | 700 | |
| Insignia meta | 28 | 700 | |
| Símbolo de operación | 26 | 700 | `+ − × ÷` (usar `−` U+2212 y `×` U+00D7, no guion ni x) |
| Guion de celda vacía | 26 | 400 | `–` |
| Texto de botón CTA | 15 | 700 | minúsculas: «convertir ceros» |
| Píldora de modo | 13 | 400 | minúsculas: «normal» / «hardcore» |
| Etiquetas | 11 | 400 | minúsculas: «tiempo», «meta», «mejor», «quedan 3» |

Todo el texto de interfaz va en **minúsculas**. Los tamaños son px lógicos sobre un ancho de 390.

### Forma

| Token | Valor |
|-------|-------|
| Radio de ficha | 14 |
| Radio de tecla, CTA, insignia | 12 |
| Radio de píldora | 20 |
| Radio de punto «quedan» | 3 |
| Borde | 1 px `border` |
| Canto de tecla | 5 px `deep` (borde inferior) |
| Canto de ficha | 7 px `deep` (borde inferior) |
| Separación entre fichas/teclas | 10 |
| Padding de pantalla | 46 arriba · 22 lados · 28 abajo |

## 3. Componentes

**Tecla (`cap`)** — base de casi todo. Cara `panel`, borde 1 px `border`, canto inferior 5 px `deep`, radio 12. Estado pulsado/activo: se rellena con `accent`, el canto baja a 2 px `accentSide` y la tecla se desplaza 3 px hacia abajo (como una tecla hundida).

**Ficha de número** — 104 de alto, ancho flexible (4 columnas). Igual que la tecla pero radio 14 y canto de 7 px; dígito 44/700 en `text`.
- *Seleccionada:* fondo y borde `accent`, canto `accentSide`, dígito `onAccent`, **sube 10 px** y lleva halo de 4 px `ring`.
- *Vacía:* sin fondo, borde discontinuo 1,5 px `border`, guion `–` en `muted`. No es pulsable.
- *Error (movimiento no válido):* no está diseñado en la referencia. Propuesta: sacudida horizontal breve + borde `danger` 300 ms. Sin texto.

**Tecla de operación** — 64 de alto, símbolo 26/700. La operación elegida usa el estado activo de la tecla.

**CTA «convertir ceros»** — 58 de alto, fondo `cta`, canto 5 px `ctaSide`, texto `onCta` 15/700. Solo en modo normal. Deshabilitado (sin ceros en el tablero): opacidad 40 %.

**Reiniciar** — tecla cuadrada de 58, icono de flecha circular en `danger` (trazo 2,4, extremos redondeados).

**Volver** — tecla de 44 × 44 con chevron.

**Píldora de modo** — borde 1 px `border`, radio 20, padding 6 × 14, texto 13.

**Insignia de meta** — 52 × 52, radio 12, fondo `accent`, «7» 28/700 en `onAccent`, con etiqueta «meta» encima.

**Indicador «quedan N»** — 4 cuadraditos de 10 px (radio 3): huecos (borde 1,5 px `muted`) por cada celda vacía, rellenos `accent` por cada número; a la derecha «quedan 3» en 11 `muted`. Centrado bajo las fichas.

## 4. Pantalla de partida (la única diseñada y aprobada)

De arriba abajo, en una columna:

1. **Cabecera** (fila, extremos): tecla volver · píldora de modo · «mejor / 00:09.1» en dos líneas, alineado a la derecha, 11 `muted`.
2. **Bloque de tiempo** (34 por debajo; fila, alineada abajo): a la izquierda etiqueta «tiempo» + cronómetro; a la derecha etiqueta «meta» + insignia.
3. **Tablero** (ocupa el espacio libre, centrado en vertical): fila de 4 fichas; 22 por debajo, el indicador «quedan».
4. **Operaciones**: fila de 4 teclas.
5. **Acciones** (20 por debajo): CTA a todo el ancho + reiniciar (58).

El cronómetro arranca en el primer toque (número u operación). La maqueta lo muestra con una décima (`00:12.4`); la app hoy lo formatea con centésimas (`formatMs` en `lib/features/common/format.dart`). No está decidido cuál se queda: preguntar al autor.

## 5. Lo que NO está diseñado (hay que proponerlo y enseñarlo antes de implementarlo)

- **Modo hardcore.** El autor quiere que cambie el color respecto a normal, pero no se ha elegido cuál. No inventarlo en silencio: proponer 2–3 opciones (p. ej. cambiar solo el acento) y enseñarlas.
- **Inicio, resultado (ganar/perder), ranking, ayuda, apodo, panel 1–9 de convertir.** Deben construirse con estos mismos tokens y componentes. El autor dijo: «una vez elegido el estilo general, elegiremos los menús y demás». Es decir: **enseñar propuestas de esas pantallas antes de darlas por buenas**.
- Estados de error, carga y sin conexión.

## 6. Cómo trabajar con el autor en diseño

- **Verifica visualmente antes de enseñar nada.** Renderiza y mira el resultado; varias rondas se perdieron por publicar diseños sin ver. En Flutter: tests golden en `test/ui/visual_test.dart` (cargan fuentes y esperan a los assets). Para maquetas HTML: Chrome headless con `--screenshot`.
- Cuando pide «estilos», se refiere al **lenguaje artístico**, no a recolores.
- Prefiere comparar opciones lado a lado en el artefacto a responder preguntas en abstracto.
- Es directo cuando algo no le gusta; no significa que haya que cambiarlo todo, sino volver a lo último que aprobó.
