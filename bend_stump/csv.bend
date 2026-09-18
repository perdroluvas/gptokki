# csv.bend — CSV parsing and 50/25/25 splitting for the decision stump.
#
# Format: header `x1,x2,y` (skipped), then one `x1,x2,y` row per line,
# where x1/x2 are natural numbers and y is 0 or 1. Blank lines are
# ignored; malformed lines are skipped and counted.
#
#   bend ../bend_stump/main.bend   (run from the repo root)
import Base

type Row is Data:
  Row{x1: Nat, x2: Nat, y: Bool}

type Split is Data:
  Split{train: List<&2, Row>, val: List<&2, Row>, test: List<&2, Row>}

# Parsing
# -------

# True on non-empty lines (blank lines are ignored, not counted).
def nonblank(l: String) -> Bool:
  match l:
    case SNil{}:
      False{}
    case SCon{h, t}:
      True{}

# The label half of a row: "1" is true, "0" is false, else malformed.
def zero(x1: Nat, x2: Nat, is0: Bool) -> Maybe<&2, Row>:
  match is0:
    case True{}:
      Some{Row{x1, x2, False{}}}
    case False{}:
      None{}

def label.go(x1: Nat, x2: Nat, is1: Bool, ys: String) -> Maybe<&2, Row>:
  match is1:
    case True{}:
      Some{Row{x1, x2, True{}}}
    case False{}:
      zero(x1, x2, String.eq(ys, "0"))

def row.go(m1: Maybe<&2, Nat>, m2: Maybe<&2, Nat>, +ys: String) -> Maybe<&2, Row>:
  match m1 m2:
    case Some{x1} Some{x2}:
      label.go(x1, x2, String.eq(ys, "1"), ys)
    case None{} None{}:
      None{}
    case None{} Some{x2}:
      None{}
    case Some{x1} None{}:
      None{}

def row(x1s: String, x2s: String, ys: String) -> Maybe<&2, Row>:
  row.go(Nat.read(x1s), Nat.read(x2s), ys)

# Exactly three comma-separated fields make a row.
def fields.fin(f1: String, f2: String, r2: List<&2, String>) -> Maybe<&2, Row>:
  match r2:
    case f3 <> Nil{}:
      row(f1, f2, f3)
    case Nil{}:
      None{}
    case f3 <> f4 <> r3:
      None{}

def fields.go(f1: String, r1: List<&2, String>) -> Maybe<&2, Row>:
  match r1:
    case Nil{}:
      None{}
    case f2 <> r2:
      fields.fin(f1, f2, r2)

def fields(fs: List<&2, String>) -> Maybe<&2, Row>:
  match fs:
    case Nil{}:
      None{}
    case f1 <> r1:
      fields.go(f1, r1)

def line(s: String) -> Maybe<&2, Row>:
  fields(String.split(s, ','))

# Drops the header line.
def body(ls: List<&2, String>) -> List<&2, String>:
  match ls:
    case Nil{}:
      Nil{}
    case h <> t:
      t

# Keeps the non-blank lines.
def blanks.put(b: Bool, h: String, t: List<&2, String>) -> List<&2, String>:
  match b:
    case True{}:
      h <> t
    case False{}:
      t

def blanks(ls: List<&2, String>) -> List<&2, String>:
  match ls:
    case Nil{}:
      Nil{}
    case +h <> t:
      blanks.put(nonblank(h), h, blanks(t))

# Parses every line.
def maybes(ls: List<&2, String>) -> List<&2, Maybe<&2, Row>>:
  match ls:
    case Nil{}:
      Nil{}
    case h <> t:
      line(h) <> maybes(t)

# Collects parsed rows and counts the skipped lines.
def collect(ms: List<&2, Maybe<&2, Row>>, acc: List<&2, Row>, bad: Nat) -> List<&2, Row> & Nat:
  match ms:
    case Nil{}:
      (acc, bad)
    case None{} <> t:
      collect(t, acc, 1n+bad)
    case Some{r} <> t:
      collect(t, r <> acc, bad)

# The rows with the skipped-line count: header dropped, blanks
# ignored, malformed lines counted as skipped.
def parsed(p: List<&2, Row> & Nat) -> List<&2, Row> & Nat:
  (rows, bad) = p
  (List.reverse(&2, Row, rows), bad)

def parse(text: String) -> List<&2, Row> & Nat:
  parsed(collect(maybes(blanks(body(String.lines(text)))), Nil{}, 0n))

# Splitting
# ---------
#
# 2:1:1 round-robin over the row order: exact 50/25/25 on row counts
# divisible by 4, off by at most one row per part otherwise. The
# interleave (rather than contiguous chunks) keeps ordered CSVs
# (e.g. all class 0 first) represented in every part.

def split.pre(a: Row, b: Row, c: Row, d: Row, s: Split) -> Split:
  match s:
    case Split{tr, va, te}:
      Split{a <> b <> tr, c <> va, d <> te}

def split.go(rows: List<&2, Row>) -> Split:
  match rows:
    case Nil{}:
      Split{Nil{}, Nil{}, Nil{}}
    case a <> Nil{}:
      Split{[a], Nil{}, Nil{}}
    case a <> b <> Nil{}:
      Split{[a, b], Nil{}, Nil{}}
    case a <> b <> c <> Nil{}:
      Split{[a, b], [c], Nil{}}
    case a <> b <> c <> d <> t:
      split.pre(a, b, c, d, split.go(t))

def split(rows: List<&2, Row>) -> Split:
  split.go(rows)

# The part lengths summed: used by main.bend and stated in LAWS.bend.
def split.sum(s: Split) -> Nat:
  match s:
    case Split{tr, va, te}:
      Nat.add(List.length(&2, Row, tr), Nat.add(List.length(&2, Row, va), List.length(&2, Row, te)))

def split.check(rows: List<&2, Row>) -> Nat:
  split.sum(split.go(rows))
