from pwn import *

# 生成 200 字节的 pattern
p = cyclic(200)
print(f"测试串：{p.decode()}")