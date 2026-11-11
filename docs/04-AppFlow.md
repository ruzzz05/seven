# App Flow — SEVEN

Estado: borrador v0.1 · Fecha: 2026-11-11 · Relacionado: [01-PRD.md](01-PRD.md), [03-UI-UX.md](03-UI-UX.md)

## 1. Mapa de navegación

```mermaid
flowchart TD
  Start([Arranque]) --> Anon{Sesión anónima<br/>guardada?}
  Anon -- No --> Auth[signInAnonymously]
  Auth --> Nick
  Anon -- Sí --> Nick{Apodo<br/>guardado?}
  Nick -- No --> Onb[/Onboarding: apodo/]
  Onb --> Home
  Nick -- Sí --> Home[/Inicio/]

  Home -->|Jugar Normal| GameN[/Juego · Normal/]
  Home -->|Jugar Hardcore| GameH[/Juego · Hardcore/]
  Home --> Rank[/Ranking/]
  Home --> Help[/Ayuda/]
  Home -->|Salir| Exit([Cerrar app])

  GameN --> Sel[Elegir operación]
  GameH --> Sel
  Sel --> Pick[Tocar 2 celdas]
  Pick --> Valid{Movimiento<br/>válido?}
  Valid -- No --> Shake[Shake + destello] --> GameN
  Valid -- Sí --> Board[Actualizar tablero]
  Board --> End{Fin de partida?}
  End -- No --> GameN
  End -- Sí --> Out{Resultado}
  Out -- Victoria --> Win[/Resultado: victoria/]
  Out -- Derrota --> Lose[/Resultado: derrota/]

  GameN -.->|Convertir, si hay 0| Pad[Panel 1–9] -.-> GameN
  Win -->|Reintentar| GameN
  Win -->|Ranking| Rank
  Win -->|Menú| Home
  Lose -->|Reintentar| GameN
  Lose -->|Menú| Home
  Rank --> Home
  Help --> Home
```

## 2. Flujo de partida (detallado)

```mermaid
sequenceDiagram
  actor J as Jugador
  participant UI as Pantalla juego
  participant E as seven_engine
  participant L as Cola local
  participant S as Edge Function
  participant DB as Postgres

  J->>UI: Pulsa "Jugar"
  UI->>S: POST /start-run (mode)
  S->>DB: INSERT runs (status=started, board)
  S-->>UI: run_id, board

  loop Hasta fin
    J->>UI: Primer toque (número u operación)
    opt Primer toque de la partida
      UI->>UI: Inicia cronómetro
    end
    J->>UI: Operación + 2 celdas (o Convertir + dígito)
    UI->>E: apply(board, mode, move)
    alt inválido
      E-->>UI: invalid
      UI->>UI: Shake, sin cambios
    else válido
      E-->>UI: nuevo board
      UI->>UI: Actualizar tablero
      UI->>E: outcome(board, mode)
    end
  end

  alt Victoria
    UI->>UI: Detener cronómetro (time_ms)
    UI->>L: Guardar moves + time_ms
    UI->>S: POST /finish-run (run_id, moves, time_ms)
    S->>S: Reproducir moves con engine.ts
    alt Válida
      S->>DB: UPDATE runs status=valid
      S-->>UI: posición
    else Rechazada
      S->>DB: UPDATE runs status=rejected
      S-->>UI: error
    end
  else Derrota
    UI->>UI: Mostrar derrota (no se envía)
  end
```

## 3. Estados de la partida

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Ready: start-run OK
  Ready --> Playing: primer toque (cronómetro inicia)
  Playing --> Selecting: tocar operación
  Selecting --> Playing: cancelar
  Selecting --> Playing: movimiento inválido
  Selecting --> Playing: movimiento válido y sigue
  Selecting --> Won: válido y único 7
  Selecting --> Lost: válido y único distinto de 7
  Playing --> Lost: sin movimientos válidos
  Playing --> PickDigit: Convertir (Normal y hay 0)
  PickDigit --> Playing: elegir dígito
  Playing --> Playing: último número 0 (Normal): solo Convertir
  Won --> Submitting
  Submitting --> Submitted: 200 OK
  Submitting --> Queued: sin red / error
  Queued --> Submitted: reintento OK
  Won --> [*]: reintentar / menú
  Lost --> [*]: reintentar / menú
```

## 4. Flujo de envío y cola offline

1. Al ganar: se guarda en `pending_runs` (JSON) antes de llamar al servidor.
2. Se llama a `finish-run`.
3. Si responde 200 con `valid`: se borra de `pending_runs`.
4. Si responde `rejected`: se borra y se registra en log local (no reintenta).
5. Si falla por red o 5xx: queda en cola.
6. Al iniciar la app y al recuperar conexión (`connectivity_plus`): se reintenta la cola en orden, máximo 3 intentos por entrada con backoff exponencial.

## 5. Flujo de errores

| Error | Pantalla | Acción |
|-------|----------|--------|
| Sin red al iniciar partida | Inicio | Jugar en modo local sin enviar al ranking; aviso "Sin conexión: partida no enviada" |
| Sin red al enviar | Resultado | "Guardado. Se enviará después." |
| Partida rechazada | Resultado | "No se pudo verificar la partida." Sin reintento. |
| Sesión anónima expirada | Cualquiera | Reautenticar en silencio; si falla, continuar sin ranking |

## 6. Permisos y datos

- Ninguno en v1 salvo INTERNET.
- Ningún dato personal recogido. Identificador de sesión anónimo de Supabase.
- Política de privacidad obligatoria en Play Console (URL pública, a publicar en una página sencilla).
