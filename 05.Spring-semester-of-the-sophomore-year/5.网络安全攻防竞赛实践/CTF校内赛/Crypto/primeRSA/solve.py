# 适用于 Ubuntu + SageMath
# 运行命令：sage solve.py
import re

# 读取你的 output.txt（三行格式：n= e= c=）
with open("output.txt", "r") as f:
    lines = f.read().splitlines()

# 自动提取三个数字
n = int(lines[0].split("=")[1])
e = int(lines[1].split("=")[1])
c = int(lines[2].split("=")[1])

# ==================== RSA 解密 ====================
phi = n - 1
d = pow(e, -1, phi)
m = pow(c, d, n)

# 转成 flag
flag = bytes.fromhex(hex(m)[2:])

# ==================== 自动反向验证 ====================
m_check = int.from_bytes(flag, "big")
c_check = pow(m_check, e, n)

print("======================================")
print("解密得到 flag =", flag)
print("======================================")
print("题目密文 c   =", c)
print("验证密文 c   =", c_check)
print("======================================")
print("✅ 验证结果：", c == c_check)
print("======================================")