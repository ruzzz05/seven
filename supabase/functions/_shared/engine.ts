// Port TypeScript de packages/seven_engine/lib/src/rules.dart.
// Mismas reglas; los vectores compartidos (rules.json) garantizan paridad.

export type Mode = 'normal' | 'hardcore';
export type Op = 'add' | 'sub' | 'mul' | 'div';
export type Cells = (number | null)[];
export type Move =
  | { type: 'op'; op: Op; i: number; j: number }
  | { type: 'convert'; digit: number };

export type ApplyResult =
  | { ok: true; board: Cells }
  | { ok: false; reason: string };

export type Outcome = 'ongoing' | 'won' | 'lost';

export const TARGET = 7;
const SIZE = 4;

export function alignRight(cells: Cells): Cells {
  const values = cells.filter((c): c is number => c !== null);
  return [...Array(SIZE - values.length).fill(null), ...values];
}

export function hasZero(cells: Cells): boolean {
  return cells.includes(0);
}

export function values(cells: Cells): number[] {
  return cells.filter((c): c is number => c !== null);
}

export function apply(board: Cells, mode: Mode, move: Move): ApplyResult {
  if (move.type === 'op') return applyOp(board, mode, move);
  return applyConvert(board, mode, move);
}

function applyOp(
  board: Cells,
  mode: Mode,
  move: { op: Op; i: number; j: number },
): ApplyResult {
  const { i, j, op } = move;
  if (i < 0 || j < 0 || i >= SIZE || j >= SIZE || i === j) {
    return { ok: false, reason: 'badIndices' };
  }
  const a = board[i];
  const b = board[j];
  if (a === null || b === null) return { ok: false, reason: 'emptyCell' };

  // El orden de los operandos no altera el resultado (igual que en Dart).
  const big = Math.max(a, b);
  const small = Math.min(a, b);
  let r: number;
  switch (op) {
    case 'add':
      r = a + b;
      break;
    case 'sub':
      r = big - small;
      break;
    case 'mul':
      r = a * b;
      break;
    case 'div':
      if (small === 0 || big % small !== 0) return { ok: false, reason: 'inexactDivision' };
      r = Math.trunc(big / small);
      break;
  }

  let digits = String(r).split('');
  if (mode === 'hardcore') {
    digits = digits.filter((d) => d !== '0');
    if (digits.length === 0) return { ok: false, reason: 'zeroResultHardcore' };
  }

  const lo = Math.min(i, j);
  const hi = Math.max(i, j);
  const next: Cells = [...board];
  next[lo] = null;
  next[hi] = null;
  next[lo] = Number(digits[0]);
  if (digits.length > 1) next[hi] = Number(digits[1]);
  return { ok: true, board: alignRight(next) };
}

function applyConvert(
  board: Cells,
  mode: Mode,
  move: { digit: number },
): ApplyResult {
  if (mode !== 'normal') return { ok: false, reason: 'convertNotAllowed' };
  if (move.digit < 1 || move.digit > 9) return { ok: false, reason: 'convertBadDigit' };
  if (!hasZero(board)) return { ok: false, reason: 'convertNoZeros' };
  return { ok: true, board: board.map((c) => (c === 0 ? move.digit : c)) };
}

export function allCandidateMoves(board: Cells, mode: Mode): Move[] {
  const out: Move[] = [];
  for (let i = 0; i < SIZE; i++) {
    for (let j = i + 1; j < SIZE; j++) {
      for (const op of ['add', 'sub', 'mul', 'div'] as Op[]) {
        out.push({ type: 'op', op, i, j });
      }
    }
  }
  if (mode === 'normal' && hasZero(board)) {
    for (let d = 1; d <= 9; d++) out.push({ type: 'convert', digit: d });
  }
  return out;
}

export function hasValidMove(board: Cells, mode: Mode): boolean {
  return allCandidateMoves(board, mode).some((m) => apply(board, mode, m).ok);
}

export function outcome(board: Cells, mode: Mode): Outcome {
  const vs = values(board);
  if (vs.length === 1) {
    const last = vs[0];
    if (last === TARGET) return 'won';
    if (last === 0 && mode === 'normal') return 'ongoing';
    return 'lost';
  }
  if (vs.length === 0) return 'lost';
  return hasValidMove(board, mode) ? 'ongoing' : 'lost';
}

export type ReplayResult =
  | { ok: true; board: Cells; outcome: Outcome }
  | { ok: false; failedAt: number; reason: string };

export function replay(start: Cells, mode: Mode, moves: Move[]): ReplayResult {
  let board = start;
  for (let k = 0; k < moves.length; k++) {
    const res = apply(board, mode, moves[k]);
    if (!res.ok) return { ok: false, failedAt: k, reason: res.reason };
    board = res.board;
  }
  return { ok: true, board, outcome: outcome(board, mode) };
}
