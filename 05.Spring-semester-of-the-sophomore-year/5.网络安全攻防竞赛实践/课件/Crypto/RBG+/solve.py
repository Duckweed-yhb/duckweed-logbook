#!/usr/bin/env python3
from ast import literal_eval
from collections import defaultdict
from Crypto.Util.number import long_to_bytes
from sage.all import PolynomialRing, Zmod, ZZ, xgcd, gcd


lines = open("challenge/output.txt").read().strip().splitlines()

N, e0 = map(ZZ, literal_eval(lines[0].split(" = ")[1]))
cs = list(map(ZZ, lines[1:]))

P = PolynomialRing(Zmod(N), "a")
a = P.gen()

es = [e0]
res = [a]  # res[i] = M_i = m^e_i
groups = defaultdict(list)

for i, c in enumerate(cs):
  t = 3 * es[-1] + 1337
  e_next = t % N
  groups[(t - e_next) // N].append(i)
  es.append(e_next)
  res.append(c - res[-1])

for k, idxs in groups.items():
  if len(idxs) < 3 or gcd(ZZ(1337) - k * N, es[1]) != 1:
    continue

  i, j, l = idxs[:3]
  z1 = res[i + 1] * res[j] ** 3 - res[j + 1] * res[i] ** 3
  z2 = res[i + 1] * res[l] ** 3 - res[l + 1] * res[i] ** 3

  g = P(z1._pari_with_name().gcd(z2._pari_with_name())).monic()
  if g.degree() != 1:
    continue

  a0 = -g[0]
  m_exp = ZZ(1337) - k * N
  m_to_exp = res[i + 1](a=a0) / res[i](a=a0) ** 3

  _, u, v = xgcd(m_exp, es[1])
  m = m_to_exp**u * (cs[0] - a0) ** v
  print(long_to_bytes(int(m)))
  break
