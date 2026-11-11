// Ejecuta los mismos vectores que packages/seven_engine/test/vectors/rules.json.
// Si Dart y TypeScript divergen, este test falla.
import { assertEquals } from 'jsr:@std/assert@1';
import { apply, outcome, type Mode, type Move } from '../functions/_shared/engine.ts';

const vectors = JSON.parse(
  await Deno.readTextFile(new URL('../../packages/seven_engine/test/vectors/rules.json', import.meta.url)),
);

for (const c of vectors.cases as Array<Record<string, any>>) {
  Deno.test(c.name, () => {
    const mode = c.mode as Mode;
    const board = c.board as (number | null)[];
    const exp = c.expect;

    if (c.move) {
      const res = apply(board, mode, c.move as Move);
      if (exp.result === 'ok') {
        assertEquals(res.ok, true);
        if (res.ok) assertEquals(res.board, exp.board);
      } else {
        assertEquals(res.ok, false);
        if (!res.ok) assertEquals(res.reason, exp.reason);
      }
    }
    if (exp.outcome) {
      assertEquals(outcome(board, mode), exp.outcome);
    }
  });
}
