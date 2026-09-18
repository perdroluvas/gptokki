# stump.bend — a pure Gini decision stump over Csv rows.
#
# A stump is one axis-aligned split: feature x1 (`False{}`) or x2
# (`True{}`), a Nat threshold, and the majority label of each side.
# The best split minimizes the weighted Gini impurity of the training
# set. Gini stays in Nat arithmetic (F32 is unprovable): for side
# counts (n0, n1) with side size n, Gini is 2*n0*n1/n^2, and splits
# are compared by cross-multiplication, never division. A split with
# an empty side is degenerate and never wins; ties keep the incumbent.
import Base
import ./csv.bend as Csv

type Stump is Data:
  Stump{feat: Bool, thr: Nat, left: Bool, right: Bool}

type Eval is Data:
  Eval{num: Nat, den: Nat, left: Bool, right: Bool}

type Best is Data:
  Best{stump: Stump, num: Nat, den: Nat}

def best.stump(b: Best) -> Stump:
  match b:
    case Best{s, x, d}:
      s

def best.num(b: Best) -> Nat:
  match b:
    case Best{s, x, d}:
      x

def best.den(b: Best) -> Nat:
  match b:
    case Best{s, x, d}:
      d

# Row access
# ----------

def val(f: Bool, r: Csv.Row) -> Nat:
  match f r:
    case False{} Csv.Row{x1, x2, y}:
      x1
    case True{} Csv.Row{x1, x2, y}:
      x2

def is1(r: Csv.Row) -> Bool:
  match r:
    case Csv.Row{x1, x2, y}:
      y

def feat(s: Stump) -> Bool:
  match s:
    case Stump{f, t, l, rr}:
      f

def thr(s: Stump) -> Nat:
  match s:
    case Stump{f, t, l, rr}:
      t

def left(s: Stump) -> Bool:
  match s:
    case Stump{f, t, l, rr}:
      l

def right(s: Stump) -> Bool:
  match s:
    case Stump{f, t, l, rr}:
      rr

# Small helpers
# -------------

def le.go(c: Cmp) -> Bool:
  match c:
    case LT{}:
      True{}
    case EQ{}:
      True{}
    case GT{}:
      False{}

def le(a: Nat, b: Nat) -> Bool:
  le.go(Nat.cmp(a, b))

def bit(b: Bool) -> Nat:
  match b:
    case True{}:
      1n
    case False{}:
      0n

def hit1(a: Bool, b: Bool) -> Nat:
  match a b:
    case True{} True{}:
      1n
    case True{} False{}:
      0n
    case False{} True{}:
      0n
    case False{} False{}:
      1n

def hit(wl: Bool, wo: Bool, l: Bool, o: Bool) -> Nat:
  match wl l:
    case True{} True{}:
      hit1(wo, o)
    case True{} False{}:
      0n
    case False{} True{}:
      0n
    case False{} False{}:
      hit1(wo, o)

# Ties go to label 1.
def maj.go(c: Cmp) -> Bool:
  match c:
    case LT{}:
      False{}
    case EQ{}:
      True{}
    case GT{}:
      True{}

def maj(n1: Nat, n0: Nat) -> Bool:
  maj.go(Nat.cmp(n1, n0))

# Counting
# --------
#
# cell counts the rows on the wanted side (wl) with the wanted label
# (wo) for feature f and threshold t: l1 l0 r1 r0 are its four calls.

def cell.go(+wl: Bool, +wo: Bool, +f: Bool, +t: Nat, rows: List<&2, Csv.Row>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +h <> tl:
      Nat.add(hit(wl, wo, le(val(f, h), t), is1(h)), cell.go(wl, wo, f, t, tl))

def ones(rows: List<&2, Csv.Row>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case h <> tl:
      Nat.add(bit(is1(h)), ones(tl))

# Scoring
# -------
#
# The weighted Gini of a split as (num, den): num is
# 2*l0*l1*r + 2*r0*r1*l and den is n*l*r, so split comparisons
# cross-multiply num1*den2 against num2*den1.

def gnum(l1: Nat, l0: Nat, r1: Nat, r0: Nat, l: Nat, r: Nat) -> Nat:
  Nat.add(Nat.mul(2n, Nat.mul(Nat.mul(l0, l1), r)), Nat.mul(2n, Nat.mul(Nat.mul(r0, r1), l)))

def gden(+l: Nat, +r: Nat) -> Nat:
  Nat.mul(Nat.mul(Nat.add(l, r), l), r)

def eval.fin(f: Bool, t: Nat, +l1: Nat, +l0: Nat, +r1: Nat, +r0: Nat, +l: Nat, +r: Nat) -> Eval:
  Eval{gnum(l1, l0, r1, r0, l, r), gden(l, r), maj(l1, l0), maj(r1, r0)}

def eval.go(f: Bool, t: Nat, +l1: Nat, +l0: Nat, +r1: Nat, +r0: Nat) -> Eval:
  eval.fin(f, t, l1, l0, r1, r0, Nat.add(l0, l1), Nat.add(r0, r1))

def eval(+f: Bool, +t: Nat, +rows: List<&2, Csv.Row>) -> Eval:
  eval.go(f, t, cell.go(True{}, True{}, f, t, rows), cell.go(True{}, False{}, f, t, rows), cell.go(False{}, True{}, f, t, rows), cell.go(False{}, False{}, f, t, rows))

def pick.cmp(c: Cmp, s1: Stump, x1: Nat, d1: Nat, s0: Stump, x0: Nat, d0: Nat) -> Best:
  match c:
    case LT{}:
      Best{s1, x1, d1}
    case EQ{}:
      Best{s0, x0, d0}
    case GT{}:
      Best{s0, x0, d0}

def pick.fin(+x1: Nat, t: Nat, f: Bool, l1: Bool, r1: Bool, best: Stump, +x0: Nat, +d1: Nat, +d0: Nat) -> Best:
  match d0:
    case 0n:
      Best{Stump{f, t, l1, r1}, x1, d1}
    case 1n+dp:
      pick.cmp(Nat.cmp(Nat.mul(x1, d0), Nat.mul(x0, d1)), Stump{f, t, l1, r1}, x1, d1, best, x0, d0)

def pick.go(+d1: Nat, x1: Nat, t: Nat, f: Bool, l1: Bool, r1: Bool, best: Stump, x0: Nat, +d0: Nat) -> Best:
  match d1:
    case 0n:
      Best{best, x0, d0}
    case 1n+dp:
      pick.fin(x1, t, f, l1, r1, best, x0, d1, d0)

def pick(e: Eval, t: Nat, f: Bool, best: Stump, x0: Nat, d0: Nat) -> Best:
  match e:
    case Eval{x1, d1, l1, r1}:
      pick.go(d1, x1, t, f, l1, r1, best, x0, d0)

# Search
# ------
#
# Every training row votes its feature value as a candidate threshold;
# duplicates are harmless (ties keep the incumbent).

def search.go(rs: List<&2, Csv.Row>, +f: Bool, +rows: List<&2, Csv.Row>, best: Stump, bx: Nat, bd: Nat) -> Best:
  match rs:
    case Nil{}:
      Best{best, bx, bd}
    case h <> tl:
      +v = val(f, h)
      +nb = pick(eval(f, v, rows), v, f, best, bx, bd)
      search.go(tl, f, rows, best.stump(nb), best.num(nb), best.den(nb))

def seed.go(+n1: Nat, +n: Nat) -> Stump:
  Stump{False{}, 0n, maj(n1, Nat.sub(n, n1)), maj(n1, Nat.sub(n, n1))}

def seed(+rows: List<&2, Csv.Row>) -> Stump:
  seed.go(ones(rows), List.length(&2, Csv.Row, rows))

def train.cmp(+x1: Nat, s1: Stump, +d1: Nat, +d2: Nat, +x2: Nat, s2: Stump) -> Best:
  match d2:
    case 0n:
      Best{s1, x1, d1}
    case 1n+dp:
      pick.cmp(Nat.cmp(Nat.mul(x1, d2), Nat.mul(x2, d1)), s1, x1, d1, s2, x2, d2)

def train.pick(+d1: Nat, x1: Nat, s1: Stump, +d2: Nat, x2: Nat, s2: Stump) -> Best:
  match d1:
    case 0n:
      Best{s2, x2, d2}
    case 1n+dp:
      train.cmp(x1, s1, d1, d2, x2, s2)

def train.fin(a: Best, b: Best) -> Best:
  match a b:
    case Best{s1, x1, d1} Best{s2, x2, d2}:
      train.pick(d1, x1, s1, d2, x2, s2)

def train.go(+rows: List<&2, Csv.Row>, +s0: Stump) -> Best:
  train.fin(search.go(rows, False{}, rows, s0, 0n, 0n), search.go(rows, True{}, rows, s0, 0n, 0n))

def train(+rows: List<&2, Csv.Row>) -> Stump:
  best.stump(train.go(rows, seed(rows)))

# Prediction
# ----------

def predict.go(left: Bool, l: Bool, rr: Bool) -> Bool:
  match left:
    case True{}:
      l
    case False{}:
      rr

def predict(s: Stump, r: Csv.Row) -> Bool:
  match s:
    case Stump{f, t, l, rr}:
      predict.go(le(val(f, r), t), l, rr)

def predict_all(+s: Stump, rows: List<&2, Csv.Row>) -> List<&2, Bool>:
  match rows:
    case Nil{}:
      Nil{}
    case h <> tl:
      predict(s, h) <> predict_all(s, tl)

def acc.go(+s: Stump, rows: List<&2, Csv.Row>) -> Nat:
  match rows:
    case Nil{}:
      0n
    case +h <> tl:
      Nat.add(hit1(predict(s, h), is1(h)), acc.go(s, tl))
