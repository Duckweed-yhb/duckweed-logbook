from sage.all import *
from Crypto.Util.number import long_to_bytes

# ===================== 题目参数 =====================
p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
K = GF(p)
E = EllipticCurve(K, (0, 4))
sn = 52437899

# ===================== 正确读取文件 =====================
with open("output.txt", "r", encoding="utf-8") as f:
    lines = [line.strip() for line in f if line.strip()]

n = int(lines[0])          # 第一行是阶 n
output = eval(lines[1])    # 第二行才是真正的输出列表

# ===================== 恢复 flag 二进制 =====================
flag_bin = []
for v in output:
    elem = K(v)
    if elem**sn == 1:
        flag_bin.append('1')
    else:
        flag_bin.append('0')

# ===================== 二进制转字符串 =====================
flag_bin_str = ''.join(flag_bin)
flag_int = int(flag_bin_str, 2)
flag = long_to_bytes(flag_int)

print("✅ 二进制长度:", len(flag_bin_str))
print("🎉 FLAG:", flag.decode())