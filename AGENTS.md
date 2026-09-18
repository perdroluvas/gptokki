# AGENTS.md — gptokki

This is a Bend project. Bend is a dependently typed, affine language:
Python-shaped syntax, explicit annotations, no inference, termination-checked
recursion, `+x` for reusable (Data) bindings, `!` for GPU offload.

When using Bend:
- run `bend guide` to learn it (full language reference, also at `~/Projects/Community/bend/guide/GUIDE.md`)
- run `bend base` to see the Base library (`bend base --types`, `bend base <Name>`)
- use `LAWS.bend` to keep important rules (human writes laws, agent never edits them)
- run `bend PROOF.bend` before committing (gate: must print `All terms check.`)
- parallelize the code whenever possible (balanced divide-and-conquer + `!`)

## Project layout

- `bend_stump/` — the project: `data.csv` (sample), `csv.bend` (parsing +
  splitting), `stump.bend` (pure Gini stump), `main.bend` (IO shell),
  `LAWS.bend` (human claims), `PROOF.bend` (agent proofs)

## bend_stump usage

```fish
bend bend_stump/main.bend                          # sample data.csv (8 rows -> 4/2/2)
STUMP_CSV=/tmp/other.csv bend bend_stump/main.bend # any CSV: header x1,x2,y, then rows
bend bend_stump/PROOF.bend                         # proof gate — must pass before commit
```

CSV: header `x1,x2,y` skipped; x1/x2 naturals, y 0/1; blank lines
ignored, malformed lines skipped and reported. Split is a 2:1:1
round-robin (exact 50/25/25 on multiples of 4). Gini stays in Nat
arithmetic (F32 is unprovable): splits compare by cross-multiplication.

## GPU (NVIDIA)

`bend_stump/gpu_demo.bend` runs one balanced kernel on CPU threads and
on the GPU (`!`). GPU builds need the CUDA toolkit (`$CUDA_HOME` or
`/usr/local/cuda` with `nvrtc.h`; driver alone is not enough):

```fish
bend bend_stump/gpu_demo.bend -o /tmp/opencode/gpu_demo
/tmp/opencode/gpu_demo --threads 8   # CPU parallel
/tmp/opencode/gpu_demo --gpu 4GB      # GPU (writes gpu_demo.gpu beside it)
```

The stump itself stays on CPU by design: file IO can't run on the
GPU, and 8 CSV rows wouldn't fill one SM. `!` is for balanced numeric
kernels (see `pow2` in `gpu_demo.bend`).

## Commands

```fish
bend bend_stump/main.bend    # check + run on the JS backend (fast dev loop)
bend bend_stump/PROOF.bend   # proof gate — must pass before commit
bend bend_stump/main.bend -o main.js   # emit JS
bend bend_stump/main.bend -o main.c    # emit C (needs clang 14+; GPU `!` needs clang 19+)
bend bend_stump/main.bend -o main      # native binary (needs clang; Fedora: sudo dnf install clang)
```

Native binaries accept `./main --threads 8` and `./main --gpu 4GB`.

## Bend rules for agents (do not violate)

1. `import Base` at the top of every `.bend` file.
2. Annotate everything: lets (`x = {3 : U32}`), binds (`x : T <- m`), operators (`(a + b : U32)`).
3. Recursion must shrink a matched parameter, first shrinking arg leftmost; `Nat` counters use `case 1n+p:`.
4. `match` only on parameters/bound vars, never computed values — push computes into helper args.
5. No `if`: `match` on `True{}` / `False{}`.
6. Closures are affine (call once); top-level defs are reusable. `~f` template args must be closed syntax.
7. Laws live in `bend_stump/LAWS.bend` (human). Proofs live in `bend_stump/PROOF.bend` (agent, `def Laws.<name>`). Never add a `def` for a law inside `LAWS.bend`.
8. `{==}` proves equal-by-computation; `%e : P` rewrites with `_` marking the replaced side.

## Reference checkout

- Bend source: `~/Projects/Community/bend` (`bend2/bend.ts` = language, do not edit; `bend2/comp.ts` = compiler; `bend2/base.bend` = prelude)
- Demos with LAWS/PROOF pairs: `~/Projects/Community/bend/demos/` (start with `io_hello_world`, then `proof_insertion_sort`)
- Papers: `~/Projects/Community/bend/paper/`
