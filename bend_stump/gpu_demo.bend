# gpu_demo.bend — proves the NVIDIA path: the same balanced kernel on
# CPU threads vs. the GPU (`!`). Needs the CUDA toolkit for the GPU
# build (Fedora: NVIDIA repo + `sudo dnf install cuda-toolkit`), then:
#
#   bend bend_stump/gpu_demo.bend -o /tmp/opencode/gpu_demo
#   /tmp/opencode/gpu_demo --threads 8   # CPU parallel
#   /tmp/opencode/gpu_demo --gpu 4GB      # RTX 5060
#
# (The JS backend ignores `!` and runs sequentially.)
import Base

# 2^d as a balanced tree: one leaf per unit of work.
def pow2(+d: Nat) -> U32:
  match d:
    case 0n:
      1
    case 1n+p:
      a b = pow2(p) pow2(p)
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    cpu : U32 = pow2(22n)
    +t1 : Nat <- IO.now()
    gpu : U32 = pow2!(22n)
    t2 : Nat <- IO.now()
    IO.print("cpu: " ++ U32.show(cpu) ++ " in " ++ Nat.show(Nat.sub(t1, t0)) ++ "ms")
    IO.print("gpu: " ++ U32.show(gpu) ++ " in " ++ Nat.show(Nat.sub(t2, t1)) ++ "ms")
