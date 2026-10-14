#!/usr/bin/env sage
from sage.all import *

def expand(n: int, base=3) -> list[int]:
    res = []
    while n:
        res.append(n % base)
        n //= base
    return res

def berlekamp_massey(sequence, q=3):
    n = len(sequence)
    C = [1]
    B = [1]
    L = 0
    m = 1
    b = 1
    for i in range(n):
        d = sequence[i]
        for j in range(1, L + 1):
            if j < len(C):
                d += C[j] * sequence[i - j]
        d %= q
        if d == 0:
            m += 1
        else:
            T = C.copy()
            coef = d * pow(b, -1, q)
            while len(C) < len(B) + m:
                C.append(0)
            for j in range(len(B)):
                C[j + m] = (C[j + m] - coef * B[j]) % q
            if 2 * L <= i:
                L = i + 1 - L
                B = T
                b = d
                m = 1
            else:
                m += 1
    return C, L

# ------------------- 读取文件 -------------------
with open("output.txt", "r") as f:
    len_key = int(f.readline().strip())
    gift_hex = f.readline().strip()
    ct_hex = f.readline().strip()

gift = bytes.fromhex(gift_hex)
ct = bytes.fromhex(ct_hex)

# ------------------- 恢复密钥流 -------------------
gift_pt_len = len_key // 3 + 3
gift_pt_bytes = b"\xff" * gift_pt_len
gift_pt = expand(int.from_bytes(gift_pt_bytes, "big"))
keystream = [(a ^ b) % 3 for a, b in zip(gift_pt, gift)]

# ------------------- BM 算法 -------------------
conn_poly, L = berlekamp_massey(keystream, 3)
mask = [ (-conn_poly[L - i] % 3) for i in range(L) ]

# ------------------- LFSR -------------------
class myLFSR:
    def __init__(self, initial_state, mask):
        self.state = initial_state.copy()
        self.mask = mask
        self.mod = 3
    def __call__(self):
        b = sum(s * m for s, m in zip(self.state, self.mask)) % self.mod
        output = self.state[0]
        self.state = self.state[1:] + [b]
        return output

lfsr = myLFSR(keystream[:L], mask)
for _ in range(len(keystream)): lfsr()

# ------------------- 解密 -------------------
flag_keystream = [lfsr() for _ in range(len(ct))]
flag_trits = [ (c ^ k) % 3 for c,k in zip(ct, flag_keystream) ]

# ------------------- 【关键】三进制 → 整数 → 字节 → 字符串 -------------------
def trits2int(trits):
    res = 0
    for t in reversed(trits):
        res = res * 3 + t
    return res

def trits2bytes(trits):
    x = trits2int(trits)
    return x.to_bytes((x.bit_length()+7)//8, "big")

flag_bytes = trits2bytes(flag_trits)

print("\n" + "="*60)
print("🎉 🎉 🎉 最终 FLAG 出炉！！！")
print(flag_bytes.decode("utf-8").strip())
print("="*60)