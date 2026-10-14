dic = "abcdefghijklmnopqrstuvwxyz{}_!1234567890"

def recover_flag(output_file="output.txt"):
    with open(output_file, 'r', encoding='utf-8') as f:
        s = f.read().strip()
    
    print(f"Output length: {len(s)} characters")
    
    stack = []          # 当前路径
    candidates = []     # 收集所有完整路径
    
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == '#':
            # 遇到 # 表示当前路径是一个完整的 word
            if len(stack) == 42:
                word = ''.join(stack)
                candidates.append(word)
            if stack:  # 回溯
                stack.pop()
            i += 1
        elif ch in dic:
            stack.append(ch)
            i += 1
        else:
            # 其他字符跳过（保险）
            i += 1
    
    print(f"Found {len(candidates)} complete 42-char words")
    
    # 筛选 flag
    flags = []
    for word in candidates:
        if word.startswith("flag{") and "}" in word:
            flags.append(word)
    
    if flags:
        print("\n=== Possible Flags ===")
        for f in sorted(set(flags)):
            print(f)
        return flags[0]
    else:
        print("No flag format found. Here are first 5 candidates:")
        for w in candidates[:5]:
            print(w[:50] + "..." if len(w) > 50 else w)
        return None

if __name__ == "__main__":
    recover_flag()