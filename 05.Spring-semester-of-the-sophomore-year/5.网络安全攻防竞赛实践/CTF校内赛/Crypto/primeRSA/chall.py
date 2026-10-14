from Crypto.Util.number import getPrime, bytes_to_long
import re

flag = open("flag.txt", "rb").read().strip()
m = bytes_to_long(flag)
assert re.fullmatch(r"flag{[A-Za-z0-9_]+}", flag.decode())
n = getPrime(1024)
e = 0x10001
c = pow(m, e, n)

print(f"{n=}")
print(f"{e=}")
print(f"{c=}")
