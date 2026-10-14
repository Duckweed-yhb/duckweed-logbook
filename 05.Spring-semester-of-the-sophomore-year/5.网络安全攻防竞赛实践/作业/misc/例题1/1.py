import base64

def decode_flag():
    # 题目给出的编码字符串
    cipher = "KFWUM6S2KVHFKUTOOQZVUVCGNJGUOMLMLAZVE5SYGJETAYZSKZVGIR22HE======"

    print("=" * 60)
    print("          MISC 双层编码解码程序")
    print("=" * 60)

    # 第一层解码：Base32
    step1 = base64.b32decode(cipher)
    print(f"[1] Base32 解码结果：{step1.decode('utf-8')}")

    # 第二层解码：Base64
    step2 = base64.b64decode(step1)
    result = step2.decode('utf-8')
    print(f"[2] Base64 解码结果：{result}")

    # 输出最终标准 Flag
    print("=" * 60)
    print(f"✅ 最终 Flag：flag{result.strip('BaseCTF')}")
    print("=" * 60)

if __name__ == '__main__':
    decode_flag()