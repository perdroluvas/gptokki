# PROOF.bend — agent-owned. Prove each law in LAWS.bend with a
# def of the same name under the Laws namespace.
import Base
import ./csv.bend as Csv
import ./stump.bend as Stump
import ./LAWS.bend as Laws

def Laws.predict_total(s, rows):
  match rows:
    case Nil{}:
      {==}
    case h <> t:
      %Laws.predict_total(s, t) : {1n+List.length(&2, Bool, Stump.predict_all(s, t)) == 1n+_ : Nat}
      {==}

def Laws.val_x1():
  {==}

def Laws.val_x2():
  {==}

def Laws.maj_tie():
  {==}

def Laws.split_four():
  {==}

def Laws.predict_hit():
  {==}
