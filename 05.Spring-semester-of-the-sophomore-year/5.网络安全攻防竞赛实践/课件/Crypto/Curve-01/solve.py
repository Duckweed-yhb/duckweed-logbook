from Crypto.Util.number import long_to_bytes
from ast import literal_eval
from sage.all import EllipticCurve, GF

enc = literal_eval(open("challenge/output.txt", "r").readlines()[1])
p = 0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAB
K = GF(p)
E = EllipticCurve(K, (0, 4))
n = E.order()
sn = 52437899
s = n // sn**2

flag = ""
for i in enc:
  if pow(i, sn, p) == 1:
    flag += "1"
  else:
    flag += "0"
print(long_to_bytes(int(flag, 2)).decode())
