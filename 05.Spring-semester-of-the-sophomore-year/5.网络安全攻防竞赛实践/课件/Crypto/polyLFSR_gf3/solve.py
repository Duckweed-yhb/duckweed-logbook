from itertools import product


def expand(n: int, base=3) -> list[int]:
  res = []
  while n:
    res.append(n % base)
    n //= base
  return res


def unexpand(trits: list[int], base=3) -> int:
  n = 0
  for t in reversed(trits):
    n = n * base + t
  return n


class myLFSR:
  def __init__(self, key: list[int], mask: list[int]):
    assert all(0 <= x < 3 for x in key)
    assert all(0 <= x < 3 for x in mask)
    assert len(key) == len(mask)

    self.state = key[:]
    self.mask = mask[:]
    self.mod = 3

  def __call__(self) -> int:
    b = sum(s * m for s, m in zip(self.state, self.mask)) % self.mod
    output = self.state[0]
    self.state = self.state[1:] + [b]
    return output


def inv3(x: int) -> int:
  x %= 3
  if x == 0:
    raise ZeroDivisionError("0 has no inverse in GF(3)")
  return x


def parse(filename="output.txt"):
  with open(filename, "r") as f:
    lines = [line.strip() for line in f if line.strip()]

  LEN = int(lines[0])
  gift = bytes.fromhex(lines[1])
  ct = bytes.fromhex(lines[2])
  return LEN, gift, ct


def rref_solve_gf3(A: list[list[int]], b: list[int], nvars: int):

  mat = []
  for row, rhs in zip(A, b):
    mat.append([(x % 3) for x in row] + [rhs % 3])

  nrows = len(mat)
  row = 0
  pivots = []

  for col in range(nvars):
    pivot = None
    for r in range(row, nrows):
      if mat[r][col] % 3 != 0:
        pivot = r
        break

    if pivot is None:
      continue

    mat[row], mat[pivot] = mat[pivot], mat[row]

    inv = inv3(mat[row][col])
    for c in range(col, nvars + 1):
      mat[row][c] = mat[row][c] * inv % 3

    for r in range(nrows):
      if r == row:
        continue

      factor = mat[r][col] % 3
      if factor == 0:
        continue

      for c in range(col, nvars + 1):
        mat[r][c] = (mat[r][c] - factor * mat[row][c]) % 3

    pivots.append(col)
    row += 1

    if row == nrows:
      break

  for r in range(nrows):
    if all(mat[r][c] % 3 == 0 for c in range(nvars)) and mat[r][nvars] % 3 != 0:
      raise ValueError("Linear system is inconsistent")

  pivot_set = set(pivots)
  free_cols = [c for c in range(nvars) if c not in pivot_set]

  x0 = [0] * nvars

  for i, col in enumerate(pivots):
    x0[col] = mat[i][nvars] % 3

  basis = []

  for free_col in free_cols:
    v = [0] * nvars
    v[free_col] = 1

    for i, pivot_col in enumerate(pivots):
      v[pivot_col] = (-mat[i][free_col]) % 3

    basis.append(v)

  return x0, basis


def add_vec_gf3(a: list[int], b: list[int]) -> list[int]:
  return [(x + y) % 3 for x, y in zip(a, b)]


def scale_vec_gf3(k: int, v: list[int]) -> list[int]:
  return [(k * x) % 3 for x in v]


def sols_gf3(x0: list[int], basis: list[list[int]]):
  dim = len(basis)

  for coeffs in product(range(3), repeat=dim):
    x = x0[:]
    for c, v in zip(coeffs, basis):
      if c:
        x = add_vec_gf3(x, scale_vec_gf3(c, v))
    yield x


def rec_keyst(LEN: int, gift: bytes) -> list[int]:
  gift_plain = b"\xff" * (LEN // 3 + 3)
  gift_trits = expand(int.from_bytes(gift_plain, "big"))
  keystream = [p ^ c for p, c in zip(gift_trits, gift)]

  if not all(0 <= x < 3 for x in keystream):
    raise ValueError("Recovered gift keystream is not in GF(3)")

  return keystream


def build_eqs(keystream: list[int], LEN: int):

  A = []
  b = []

  for t in range(len(keystream) - LEN):
    A.append(keystream[t : t + LEN])
    b.append(keystream[t + LEN])

  return A, b


def decrypt(
  init_state: list[int],
  mask: list[int],
  known_stream_len: int,
  ct: bytes,
) -> bytes | None:
  lfsr = myLFSR(init_state, mask)

  for _ in range(known_stream_len):
    lfsr()

  stream = [lfsr() for _ in range(len(ct))]
  pt_trits = [c ^ s for c, s in zip(ct, stream)]

  if not all(0 <= x < 3 for x in pt_trits):
    return None

  pt_int = unexpand(pt_trits)
  pt = pt_int.to_bytes((pt_int.bit_length() + 7) // 8, "big")
  return pt


def solve():
  LEN, gift, ct = parse("challenge/output.txt")

  keystream = rec_keyst(LEN, gift)
  init_state = keystream[:LEN]

  A, b = build_eqs(keystream, LEN)
  x0, basis = rref_solve_gf3(A, b, LEN)

  for mask in sols_gf3(x0, basis):
    pt = decrypt(
      init_state=init_state,
      mask=mask,
      known_stream_len=len(keystream),
      ct=ct,
    )

    if pt is None:
      continue

    if b"HITCTF" in pt:
      print(pt.decode(errors="replace"))
      return

  else:
    print("[?] No valid flag...")


if __name__ == "__main__":
  solve()
