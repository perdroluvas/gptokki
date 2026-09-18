# LAWS.bend — human-owned. State the rules here; never add a `def`
# for a law in this file. PROOF.bend must prove each law.
# The agent must not edit the laws, only prove them.
import Base
import ./csv.bend as Csv
import ./stump.bend as Stump

# LAW: prediction is total: one label comes back per input row.
law predict_total:
  for s: Stump.Stump
  for rows: List<&2, Csv.Row>
  {List.length(&2, Bool, Stump.predict_all(s, rows)) == List.length(&2, Csv.Row, rows) : Nat}

# LAW: False{} selects x1.
law val_x1:
  {Stump.val(False{}, Csv.Row{3n, 7n, True{}}) == 3n : Nat}

# LAW: True{} selects x2.
law val_x2:
  {Stump.val(True{}, Csv.Row{3n, 7n, True{}}) == 7n : Nat}

# LAW: majority ties go to label 1.
law maj_tie:
  {Stump.maj(5n, 5n) == True{} : Bool}

# LAW: a 4-row cycle splits 2:1:1 (train/val/test).
law split_four:
  {Csv.split.go([Csv.Row{0n, 0n, False{}}, Csv.Row{1n, 1n, False{}}, Csv.Row{2n, 2n, True{}}, Csv.Row{3n, 3n, True{}}]) == Csv.Split{[Csv.Row{0n, 0n, False{}}, Csv.Row{1n, 1n, False{}}], [Csv.Row{2n, 2n, True{}}], [Csv.Row{3n, 3n, True{}}]} : Csv.Split}

# LAW: predict follows the threshold side.
law predict_hit:
  {Stump.predict(Stump.Stump{False{}, 2n, False{}, True{}}, Csv.Row{3n, 9n, True{}}) == True{} : Bool}
