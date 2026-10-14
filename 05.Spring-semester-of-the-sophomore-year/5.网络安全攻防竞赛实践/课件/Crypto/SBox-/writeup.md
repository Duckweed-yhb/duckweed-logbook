因为允许自定义SBox所以这题的解法实在是太多了，直接给一个AI的解法吧：

---

题目允许我们自定义一个 256 元素的 `sbox`，然后服务端随机生成 `key` 和 `nonce`，使用如下流密码加密：

```python
stream += block_cipher.block_enc(self.nonce)
self.nonce = block_cipher.block_enc(self.nonce)
```

也就是说这是一个类似 OFB 的结构：

$$
X_{i+1} = E(X_i)
$$

输出流为：

$$
X_1, X_2, X_3, \dots
$$

块大小为 4 字节。块加密函数中没有字节间混淆，因此 4 个字节位置是完全独立的。

每个字节位置的 4 轮加密形如：

$$
x \mapsto S(x \oplus k_0)
$$

连续做 4 轮。

我们的目标是构造恶意 `sbox`，让加密流周期极短，从而用已知明文 `HITCTF{` 恢复 keystream。

---

## 构造恶意 S-box

选择：

$$
S(x) = A(x) \oplus 1
$$

其中 $A$ 是 8 bit 循环左移 2 位：

$$
A(x) = \operatorname{rotl}_2(x)
$$

因为循环左移 2 位做 4 次会回到原值，所以：

$$
A^4 = I
$$

对应代码：

```python
def rotl8(x: int, r: int) -> int:
    return ((x << r) & 0xff) | (x >> (8 - r))

sbox = [rotl8(x, 2) ^ 1 for x in range(256)]
```

该 `sbox` 是仿射置换，所以一定是合法 permutation。

---

## 为什么 4 轮后变成异或平移

单字节一轮为：

$$
x \mapsto S(x \oplus k)
$$

代入我们的构造：

$$
S(x \oplus k) = A(x \oplus k) \oplus 1
$$

也就是：

$$
A(x) \oplus A(k) \oplus 1
$$

连续 4 轮后，关于输入 $x$ 的线性部分为：

$$
A^4(x)
$$

由于：

$$
A^4 = I
$$

所以 4 轮后的形式一定是：

$$
F(x) = x \oplus d
$$

其中 $d$ 和未知 key 有关，但我们不需要知道它。

因此每个字节位置的块加密都是一个异或平移：

$$
E(X) = X \oplus D
$$

其中 $D$ 是 4 字节常量。

---

## 流密码周期

流生成过程是：

$$
X_{i+1} = E(X_i)
$$

而现在：

$$
E(X) = X \oplus D
$$

所以：

$$
X_1 = X_0 \oplus D
$$

$$
X_2 = X_0
$$

$$
X_3 = X_0 \oplus D
$$

$$
X_4 = X_0
$$

因此输出块周期为 2 个 block。

每个 block 是 4 字节，所以 keystream 的字节周期为：

$$
2 \times 4 = 8
$$

也就是说：

$$
K_i = K_{i \bmod 8}
$$

---

## 绕过题目检查

题目有两个关键检查。

### 固定点数量

题目要求：

$$
\#\{x : S(x) = x\} < 4
$$

我们使用：

$$
S(x) = \operatorname{rotl}_2(x) \oplus 1
$$

该构造没有固定点，因此满足条件。

### 随机差分检查

题目检查 8 次：

```python
sbox[a] ^ sbox[b] != a ^ b
```

对于我们的仿射 S-box，有：

$$
S(a) \oplus S(b) = A(a \oplus b)
$$

检查失败当且仅当：

$$
A(a \oplus b) = a \oplus b
$$

也就是差分 $d = a \oplus b$ 被 $A$ 固定。

对 $\operatorname{rotl}_2$ 而言，满足 $A(d)=d$ 的值只有 4 个：

$$
0x00, 0x55, 0xaa, 0xff
$$

所以单次检查失败概率为：

$$
\frac{4}{256} = \frac{1}{64}
$$

8 次全部通过的概率为：

$$
\left(\frac{63}{64}\right)^8 \approx 0.882
$$

如果服务端随机检查失败，重新连接即可。

---

## 利用已知明文恢复 flag

我们输入 prefix 长度为 0，使明文直接从 flag 开始。

flag 已知前缀为：

```text
HITCTF{
```

长度为 7。

由于 keystream 周期为 8，我们可以通过前 7 个已知明文字节恢复 7 个 keystream 字节：

$$
K_i = C_i \oplus P_i
$$

还剩 1 个 keystream 字节未知，直接枚举 256 种可能即可。

题目还输出了：

```python
sha3_384(flag).hexdigest()
```

所以我们枚举最后 1 个 keystream 字节，解密整个 ciphertext，然后用 hash 校验即可。

---

感兴趣的同学可以试试看，如果传入其他不同结构的SBox，这个对称密码系统会展现出什么行为。