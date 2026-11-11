import { replay, type Mode, type Move } from '../_shared/engine.ts';
import { adminClient, corsHeaders, json, userClient } from '../_shared/http.ts';

const MAX_MOVES = 200;
const LATENCY_TOLERANCE_MS = 2000;
/** Tiempo mínimo plausible por modo (ajustar con datos reales). */
const MIN_TIME_MS: Record<Mode, number> = { normal: 3000, hardcore: 3000 };

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const user = userClient(req);
  const { data: auth, error: authErr } = await user.auth.getUser();
  if (authErr || !auth.user) return json({ error: 'unauthorized' }, 401);
  const uid = auth.user.id;

  const body = await req.json().catch(() => null);
  const runId = body?.run_id;
  const moves = body?.moves;
  const timeMs = body?.time_ms;
  if (typeof runId !== 'string' || !Array.isArray(moves) || typeof timeMs !== 'number') {
    return json({ error: 'bad_request' }, 400);
  }

  const admin = adminClient();
  const { data: run } = await admin
    .from('runs')
    .select('id, mode, initial_board, status, started_at')
    .eq('id', runId)
    .eq('user_id', uid)
    .maybeSingle();
  if (!run) return json({ error: 'not_found' }, 404);
  if (run.status !== 'started') return json({ status: 'rejected', reason: 'not_started' });

  const mode = run.mode as Mode;
  const reject = async (reason: string) => {
    await admin.from('runs').update({ status: 'rejected', moves }).eq('id', runId);
    return json({ status: 'rejected', reason });
  };

  if (moves.length > MAX_MOVES) return reject('too_many_moves');

  const res = replay(run.initial_board, mode, moves as Move[]);
  if (!res.ok) return reject(`invalid_move_${res.failedAt}_${res.reason}`);
  if (res.outcome !== 'won') return reject('not_won');

  const now = Date.now();
  const elapsed = now - Date.parse(run.started_at);
  if (timeMs > elapsed + LATENCY_TOLERANCE_MS) return reject('time_too_high');
  if (timeMs < MIN_TIME_MS[mode]) return reject('time_too_low');

  const { error: upErr } = await admin
    .from('runs')
    .update({
      status: 'valid',
      moves,
      time_ms: Math.round(timeMs),
      finished_at: new Date(now).toISOString(),
    })
    .eq('id', runId);
  if (upErr) return json({ error: 'db_error' }, 500);

  // Posición con el JWT del jugador (get_my_rank usa auth.uid()).
  const { data: rank } = await user.rpc('get_my_rank', { p_mode: mode });
  const position = Array.isArray(rank) && rank.length > 0 ? rank[0].position : null;

  return json({ status: 'valid', position });
});
