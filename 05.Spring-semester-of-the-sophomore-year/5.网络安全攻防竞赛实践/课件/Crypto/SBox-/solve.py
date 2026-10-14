#!/usr/bin/env python3
from pwn import remote, context
from hashlib import sha3_384
from itertools import product


def rotl8(x: int, r: int) -> int:
  return ((x << r) & 0xFF) | (x >> (8 - r))


def make_sbox() -> list[int]:
  sbox = [rotl8(x, 2) ^ 1 for x in range(256)]
  assert len(set(sbox)) == 256
  assert all(0 <= x < 256 for x in sbox)
  assert sum(i == sbox[i] for i in range(256)) < 4
  bad = [d for d in range(256) if rotl8(d, 2) == d]
  assert bad == [0x00, 0x55, 0xAA, 0xFF]

  return sbox


def recover_flag(digest_hex: str, ct_hex: str) -> bytes:
  ct = bytes.fromhex(ct_hex.strip())
  digest_hex = digest_hex.strip()
  known = b"HITCTF{"
  ks = [None] * 8
  for i, p in enumerate(known):
    v = ct[i] ^ p
    r = i % 8
    if ks[r] is not None and ks[r] != v:
      raise ValueError("inconsistent known plaintext")
    ks[r] = v

  unknown = [i for i, v in enumerate(ks) if v is None]

  for vals in product(range(256), repeat=len(unknown)):
    cur_ks = ks[:]
    for idx, val in zip(unknown, vals):
      cur_ks[idx] = val
    pt = bytes(c ^ cur_ks[i % 8] for i, c in enumerate(ct))
    if pt.startswith(known) and sha3_384(pt).hexdigest() == digest_hex:
      return pt
  raise RuntimeError("flag not found")


if __name__ == "__main__":
  context.log_level = "error"
  sbox = make_sbox()
  sbox_line = " ".join(map(str, sbox)).encode()

  io = remote("10.249.14.223", 32806)

  io.recvuntil(b"sbox > ")
  io.sendline(sbox_line)
  io.recvuntil(b"prefix? > ")
  io.sendline(b"0")
  digest_hex = io.recvline().strip().decode()
  ct_hex = io.recvline().strip().decode()
  flag = recover_flag(digest_hex, ct_hex)
  print(flag.decode())
  io.close()
