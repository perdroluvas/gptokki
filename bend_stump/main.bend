# main.bend — the IO shell: reads the CSV, trains the stump, prints accuracies.
#
# The CSV path comes from the STUMP_CSV env var, else bend_stump/data.csv
# (run from the repo root so the fallback resolves). Format and splitting
# live in csv.bend; the learning lives in stump.bend.
#
#   bend bend_stump/main.bend
#   STUMP_CSV=/tmp/other.csv bend bend_stump/main.bend
import Base
import ./csv.bend as Csv
import ./stump.bend as Stump

def path(r: Result<&1, &1, U32 & String, String>) -> String:
  match r:
    case Done{value}:
      value
    case Fail{_}:
      "bend_stump/data.csv"

def text(m: File & Result<&1, &1, U32 & String, String>) -> IO(String):
  (f, r) = m
  do IO<String>:
    Unit <- File.close(f)
    IO.pass(String, r)

def opened(ro: Result<&1, &1, U32 & String, File>, path: String) -> IO(String):
  match ro path:
    case Done{f} p:
      do IO<String>:
        m : File & Result<&1, &1, U32 & String, String> <- File.read(f, 1048576)
        text(m)
    case Fail{_} p:
      IO.die(String, 1, "cannot open " ++ p)

def feat(f: Bool) -> String:
  match f:
    case True{}:
      "x2"
    case False{}:
      "x1"

def bit(b: Bool) -> String:
  match b:
    case True{}:
      "1"
    case False{}:
      "0"

def frac(c: Nat, n: Nat) -> String:
  Nat.show(c) ++ "/" ++ Nat.show(n)

def print(path: String, +rows: List<&2, Csv.Row>, bad: Nat, +tr: List<&2, Csv.Row>, +va: List<&2, Csv.Row>, +te: List<&2, Csv.Row>, +s: Stump.Stump) -> IO(Unit):
  do IO<Unit>:
    IO.print("path: " ++ path)
    IO.print("rows: " ++ Nat.show(List.length(&2, Csv.Row, rows)) ++ " (skipped " ++ Nat.show(bad) ++ ")")
    IO.print("train/val/test: " ++ Nat.show(List.length(&2, Csv.Row, tr)) ++ "/" ++ Nat.show(List.length(&2, Csv.Row, va)) ++ "/" ++ Nat.show(List.length(&2, Csv.Row, te)))
    IO.print("stump: " ++ feat(Stump.feat(s)) ++ " <= " ++ Nat.show(Stump.thr(s)) ++ " -> " ++ bit(Stump.left(s)) ++ "/" ++ bit(Stump.right(s)))
    IO.print("train acc: " ++ frac(Stump.acc.go(s, tr), List.length(&2, Csv.Row, tr)))
    IO.print("val acc: " ++ frac(Stump.acc.go(s, va), List.length(&2, Csv.Row, va)))
    IO.print("test acc: " ++ frac(Stump.acc.go(s, te), List.length(&2, Csv.Row, te)))

def report(path: String, rows: List<&2, Csv.Row>, bad: Nat, sp: Csv.Split) -> IO(Unit):
  match sp:
    case Csv.Split{+tr, va, te}:
      print(path, rows, bad, tr, va, te, Stump.train(tr))

def run(path: String, p: List<&2, Csv.Row> & Nat) -> IO(Unit):
  (+rows, bad) = p
  report(path, rows, bad, Csv.split.go(rows))

def main() -> IO(Unit):
  do IO<Unit>:
    env : Result<&1, &1, U32 & String, String> <- IO.get_env("STUMP_CSV")
    +path : String = path(env)
    ro : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    text : String <- opened(ro, path)
    run(path, Csv.parse(text))
