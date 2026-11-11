import { adminClient, corsHeaders, json, userClient } from '../_shared/http.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const user = userClient(req);
  const { data: auth, error: authErr } = await user.auth.getUser();
  if (authErr || !auth.user) return json({ error: 'unauthorized' }, 401);
  const uid = auth.user.id;

  const body = await req.json().catch(() => null);
  const mode = body?.mode;
  if (mode !== 'normal' && mode !== 'hardcore') return json({ error: 'bad_mode' }, 400);

  const admin = adminClient();

  // Perfil mínimo (sin apodo). Idempotente.
  await admin.from('profiles').upsert({ id: uid }, { onConflict: 'id', ignoreDuplicates: true });

  // Una sola partida activa por usuario.
  await admin.from('runs').update({ status: 'abandoned' }).eq('user_id', uid).eq('status', 'started');

  // Tablero generado en servidor: 4 dígitos 1–9.
  const rnd = new Uint32Array(4);
  crypto.getRandomValues(rnd);
  const board = Array.from(rnd, (v) => (v % 9) + 1);

  const { data: run, error } = await admin
    .from('runs')
    .insert({ user_id: uid, mode, initial_board: board })
    .select('id, started_at')
    .single();
  if (error || !run) return json({ error: 'db_error' }, 500);

  return json({ run_id: run.id, board, mode, started_at: run.started_at });
});
