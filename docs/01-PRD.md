# PRD — SEVEN (versión Flutter)

Estado: borrador v0.1 · Fecha: 2026-11-11 · Fuente de reglas: explicación del autor del juego original (Unity, beta "SinSonido").

## 1. Resumen

SEVEN es un puzzle aritmético de un jugador en español. Hay 4 números en el tablero. El jugador aplica operaciones entre dos de ellos hasta que solo quede un número. El objetivo es que ese último número sea **7**. La puntuación es el **tiempo**: menor tiempo, mejor posición en el ranking mundial.

Versión Flutter: mismo juego, publicado en Google Play y, en fase posterior, App Store. Añade ranking global online.

## 2. Objetivos

- O1. Reproducir fielmente las reglas de la beta (modo Normal y Hardcore).
- O2. Publicar en Google Play en la primera release.
- O3. Ranking mundial por modo, basado en tiempo, con validación de partidas en servidor.
- O4. Base de código única iOS/Android para publicar en App Store sin reescribir.

No objetivos (v1):
- Sonido y música (la beta no tenía audio).
- Cuentas con email/contraseña, login social.
- Monetización, anuncios.
- Modos o niveles adicionales.

## 3. Usuarios

Jugador casual y speedrunner de puzzles que busca mejorar su tiempo y compararlo con otros. No necesita registro para jugar en local; sí necesita un apodo para aparecer en el ranking.

## 4. Reglas del juego

### 4.1 Tablero

- 4 posiciones fijas, numeradas de izquierda (0) a derecha (3).
- Cada celda contiene un dígito 0–9 o está vacía.
- Las celdas vacías se muestran como `-`.
- Los números se alinean siempre a la **derecha**: las vacías se acumulan a la izquierda. (Tablero siempre con forma `- - a b`, nunca `a - b -`.)
- Inicio: 4 dígitos generados aleatoriamente en 1–9. *(Supuesto: no incluye 0 al inicio.)*

### 4.2 Operaciones

Operaciones: `+`, `−`, `×`, `÷`.

Flujo: pulsar el botón de operación → pulsar dos celdas con número. El orden de los dos toques no cambia el resultado: la resta es `|a − b|` y la división es `mayor ÷ menor` (debe ser exacta y el menor no puede ser 0). No hay botón de igual: al seleccionar la segunda celda la operación se ejecuta automáticamente.

Resultado:
1. Se calcula `r = a op b`.
2. **Inválido** si `r < 0`, si `b = 0` en división, o si la división no es exacta. Un movimiento inválido no cambia el tablero, no penaliza y la partida continúa.
3. Los dígitos de `r` se escriben en las celdas de los operandos, en orden izquierda → derecha. Si `r` tiene un solo dígito, va a la celda izquierda y la derecha queda vacía.
4. Se alinea el tablero a la derecha.

Ejemplos (normativos):
- Tablero `- - 3 5`, multiplicar → `15` → tablero `- - 1 5`.
- Tablero `- - 2 3`, sumar → `5` → tablero `- - - 5`.
- Modo Normal, tablero `- - 4 5`, multiplicar → `20` → tablero `- - 2 0` (el 0 se conserva).
- Modo Hardcore, tablero `- - 4 5`, multiplicar → `20` → el 0 se descarta → tablero `- - - 2`.

### 4.3 Ceros (solo modo Normal)

- Un 0 puede aparecer por resultados como `20`.
- El botón **Convertir** aparece activo cuando hay al menos un 0 en el tablero.
- Al pulsar Convertir se abre el panel 1–9. Al elegir un dígito `d`, **todos** los ceros del tablero pasan a `d`.
- Convertir no es un movimiento de operación y no suma nada más que el tiempo ya transcurrido. *(Supuesto: no consume turno ni penaliza.)*

### 4.4 Modo Hardcore

- Igual que Normal, pero:
  - No existe el botón Convertir.
  - Los dígitos 0 nunca quedan en el tablero: se descartan del resultado.
  - Un movimiento cuyo resultado solo tiene ceros (ej. `3 − 3 = 0`) es **inválido**. *(Supuesto.)*
- Cambia el color del menú y de la interfaz del modo.

### 4.5 Fin de partida

- **Victoria:** el tablero tiene un único número y es `7`. Se registra el tiempo.
- **Derrota:** el tablero tiene un único número distinto de `7`, excepto en Normal con `0` (ver abajo).
- **Normal, último número = 0:** la partida no termina. El jugador debe pulsar Convertir y elegir un dígito.
- **Sin movimientos válidos** (hay 2+ números y ninguna operación posible): derrota. *(Supuesto.)*

### 4.6 Cronómetro y puntuación

- El cronómetro cuenta hacia arriba desde el primer toque de la partida (un número o una operación) hasta la victoria.
- Puntuación = tiempo de victoria en milisegundos. Menor es mejor.
- No hay puntos, combos ni penalizaciones.
- Ranking separado por modo.

### 4.7 Menús

- **Jugar Normal**, **Jugar Hardcore**, **Ayuda**, **Ranking**, **Salir**.
- **Reinicio** dentro de partida: nuevo tablero, cronómetro a cero. *(Supuesto.)*

## 5. Requisitos funcionales

| ID | Requisito | Prioridad |
|----|-----------|-----------|
| RF-01 | Generar tablero inicial de 4 dígitos 1–9 | Alta |
| RF-02 | Ejecutar `+ − × ÷` sobre dos celdas según 4.2 | Alta |
| RF-03 | Resta siempre en valor absoluto; rechazar divisiones no exactas sin cambiar el tablero | Alta |
| RF-04 | Alinear tablero a la derecha y mostrar `-` | Alta |
| RF-05 | Modo Normal: conservar 0 en resultados | Alta |
| RF-06 | Modo Normal: botón Convertir y panel 1–9 que cambia todos los 0 | Alta |
| RF-07 | Modo Hardcore: descartar 0 de resultados; sin Convertir | Alta |
| RF-08 | Detectar victoria (único 7) y derrota (único ≠ 7) | Alta |
| RF-09 | Cronómetro visible, en ms internamente | Alta |
| RF-10 | Pantallas de victoria y derrota con Reintentar y Menú | Alta |
| RF-11 | Enviar partida ganada al servidor para ranking | Alta |
| RF-12 | Ranking global top N por modo, orden ascendente por tiempo | Alta |
| RF-13 | Elegir apodo la primera vez | Media |
| RF-14 | Mejor tiempo personal guardado en local | Media |
| RF-15 | Pantalla de Ayuda con reglas resumidas | Media |
| RF-16 | Textos en español | Alta |

## 6. Requisitos no funcionales

- Rendimiento: respuesta a un toque < 100 ms. Cálculo de movimiento sin red.
- Offline: se puede jugar sin conexión. Solo el envío al ranking requiere red; si falla, se reintenta al volver la conexión.
- Integridad: partidas validadas en servidor antes de entrar al ranking.
- Accesibilidad: tamaño de toque mínimo 48 dp; contraste AA en ambos modos.
- Orientación: vertical. *(Supuesto a confirmar.)*
- Plataformas v1: Android 8.0 (API 26) o superior. iOS en fase 2.
- Privacidad: no se piden datos personales. Identificador anónimo de sesión + apodo.

## 7. Métricas de éxito

- Partidas completadas / partidas iniciadas > 40 %.
- Tasa de envío al ranking de partidas ganadas > 90 %.
- Crash-free sessions > 99,5 %.
- Primer lanzamiento en Google Play con calificación ≥ 4,0 (tras 50 valoraciones).

## 8. Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Reglas mal interpretadas respecto a la beta | Alto | Tests de reglas con casos de tabla (sección 4). Probar la beta en paralelo. |
| Trampas en el ranking (tiempos falsos) | Medio | Validación de movimientos en servidor; tiempo mínimo plausible. |
| Puntos ambiguos (Convertir, inicio de cronómetro) | Medio | Confirmar supuestos marcados en este documento antes de la fase 1. |
| Cuenta de Apple (99 USD/año) y build iOS | Bajo para v1 | Fase 2. |

## 9. Supuestos abiertos (confirmar)

1. Orientación vertical.
2. Idioma solo español.
3. ~~Cronómetro arranca al mostrarse el tablero.~~ Confirmado: arranca en el primer toque.
4. Convertir no consume tiempo ni turno.
5. `−` y `÷`: primer toque = operando izquierdo.
6. Resultado sin dígitos válidos en Hardcore (`0`) = movimiento inválido.
7. Sin movimientos válidos = derrota.
8. Reinicio genera tablero nuevo.
9. Contenido exacto de la pantalla de Ayuda.
10. Sin sonido en v1.

## 10. Fuera de alcance v1

Sonido, cuentas sociales, anuncios, modos extra, tablets optimizadas, iOS, traducciones.
