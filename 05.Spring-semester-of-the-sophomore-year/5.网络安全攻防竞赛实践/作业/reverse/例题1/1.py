enc = "gm`fzy1s^0r^r1^d5{x|"
flag = ""
for c in enc:
    flag += chr(ord(c) ^ 0x1)
print("flag{" + flag + "}")