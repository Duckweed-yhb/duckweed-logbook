from cipher import myStream
from secrets import token_bytes, choice
from hashlib import sha3_384

ALPHABET = "0123456789abcdef"
flag = open("flag.txt", "rb").read().strip()
assert flag.startswith(b"HITCTF{")
key, nonce = token_bytes(16), token_bytes(4)
sbox = list(map(int, input("🫧 Give me your sbox > ").strip().split(" ")))
count = 0

for idx, val in enumerate(sbox):
  if idx == val:
    count += 1

assert count < 4
assert len(set(sbox)) == 256 and all(0 <= x < 256 for x in sbox)

len_pre = int(input("🫧 Want some prefix? > "))
prefix = "".join(choice(ALPHABET) for _ in range(len_pre)).encode()
cipher = myStream(sbox, key, nonce)
ct = cipher.enc(prefix + flag)

print(sha3_384(flag).hexdigest())
print(ct.hex())
