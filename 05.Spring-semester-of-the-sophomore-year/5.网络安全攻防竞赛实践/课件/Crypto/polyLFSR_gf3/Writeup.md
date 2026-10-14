# Writeup

## 题目

`chall.py` 实现了一个基于三元域 $\mathbb{F}_3$ 的 LFSR 流密码。

程序流程如下：

1. 将随机 8 字节密钥转换为三进制展开，得到 `KEY`。
2. 随机生成同长度的 `MASK`。
3. 使用 `KEY` 和 `MASK` 初始化 LFSR。
4. 先加密一段已知明文：

   $$
   \texttt{gift\_pt} = \texttt{b"\textbackslash xff"} \times \left(\left\lfloor \frac{L}{3} \right\rfloor + 3\right)
   $$

   其中 $L = \texttt{len(KEY)}$。

5. 再继续使用同一个 LFSR 加密 flag。
6. 输出：

   - `len(KEY)`
   - `gift`
   - `ct`

这里的关键点是：`gift` 对应的明文是完全已知的，因此可以从中恢复一段连续的密钥流。而 LFSR 的输出序列满足线性递推关系，可以使用 Berlekamp-Massey 算法恢复最短线性递推，即恢复 LFSR 的连接多项式。

---

## LFSR 结构

题目中的 LFSR 定义如下：

```python
b = sum(s * m for s, m in zip(self.state, self.mask)) % 3
output = self.state[0]
self.state = self.state[1:] + [b]
```

设 LFSR 长度为 $L$，当前状态为：

$$
(s_t, s_{t+1}, \dots, s_{t+L-1})
$$

输出为：

$$
z_t = s_t
$$

反馈值为：

$$
s_{t+L} = \sum_{i=0}^{L-1} m_i s_{t+i} \pmod 3
$$

其中 $m_i$ 是 `MASK` 的第 $i$ 个元素。

因此，整个密钥流序列 $\{z_t\}$ 满足一个三元域上的线性递推：

$$
z_{t+L} = \sum_{i=0}^{L-1} m_i z_{t+i} \pmod 3
$$

这说明，只要获得足够长的一段连续密钥流，就可以恢复出对应的线性递推关系。

---

## 加密方式

`encrypt` 函数中，明文首先被转换成三进制展开：

```python
pt = expand(int.from_bytes(msg, "big"))
```

`expand` 得到的是低位在前的三进制数字列表。也就是说，如果整数为 $n$，则：

$$
n = \sum_{i=0}^{k-1} p_i 3^i
$$

对应：

$$
\texttt{expand}(n) = [p_0, p_1, \dots, p_{k-1}]
$$

其中每个 $p_i \in \{0,1,2\}$。

之后加密为：

$$
c_i = p_i \oplus z_i
$$

这里的 $\oplus$ 是 Python 中的按位异或，而不是模 $3$ 加法。

由于异或满足自反性：

$$
a \oplus b \oplus a = b
$$

所以在已知明文 $p_i$ 和密文 $c_i$ 的情况下，可以直接恢复密钥流：

$$
z_i = p_i \oplus c_i
$$

这就是 `gift` 的作用。

---

## 已知明文恢复密钥流

题目输出的 `gift` 是对已知明文的加密结果：

```python
gift = cipher.encrypt(b"\xff" * (len(KEY) // 3 + 3))
```

因此攻击者可以在本地构造相同的明文：

$$
\texttt{gift\_pt} = \texttt{b"\textbackslash xff"} \times \left(\left\lfloor \frac{L}{3} \right\rfloor + 3\right)
$$

将其转换成三进制展开，得到明文三进制序列 $\{p_i\}$。

由输出的 `gift` 得到密文序列 $\{c_i\}$，于是可以计算：

$$
z_i = p_i \oplus c_i
$$

得到一段连续的 LFSR 输出序列。

题目中输出了 `len(KEY)`，也就是 LFSR 的长度 $L$。`gift` 的长度设计得足以提供大约 $2L$ 个密钥流元素，而恢复一个长度为 $L$ 的线性递推通常需要至少 $2L$ 个连续项。

---

## Berlekamp-Massey 算法原理

Berlekamp-Massey 算法用于在有限域上，从一个序列中恢复能够生成该序列的最短线性递推关系。

对于序列：

$$
s_0, s_1, \dots, s_{n-1}
$$

算法希望找到最小的 $L$，以及系数 $c_1, c_2, \dots, c_L$，使得对足够多的 $N$ 有：

$$
s_N + c_1 s_{N-1} + c_2 s_{N-2} + \cdots + c_L s_{N-L} = 0
$$

也可以写成：

$$
s_N = -\sum_{i=1}^{L} c_i s_{N-i}
$$

对应的连接多项式为：

$$
C(x) = 1 + c_1 x + c_2 x^2 + \cdots + c_L x^L
$$

在本题中，所有运算都在 $\mathbb{F}_3$ 上进行，即：

$$
0,1,2
$$

并且所有加法、乘法都对 $3$ 取模。

### 核心思想

Berlekamp-Massey 算法逐项扫描序列，并维护当前能够解释已扫描前缀的最短递推关系。

当扫描到第 $N$ 项时，计算当前递推关系对 $s_N$ 的预测误差，也称 discrepancy：

$$
d_N = s_N + \sum_{i=1}^{L} c_i s_{N-i}
$$

如果：

$$
d_N = 0
$$

说明当前递推关系仍然成立，不需要修改。

如果：

$$
d_N \neq 0
$$

说明当前递推关系无法解释第 $N$ 项，需要修正连接多项式。

修正的大致形式为：

$$
C(x) \leftarrow C(x) - \frac{d_N}{b} x^m B(x)
$$

其中：

- $C(x)$ 是当前连接多项式。
- $B(x)$ 是上一次发生有效更新时保存的旧连接多项式。
- $b$ 是当时的非零 discrepancy。
- $m$ 表示距离上次更新已经过去了多少步。
- 所有运算都在 $\mathbb{F}_3$ 上完成。

如果当前序列前缀表明线性复杂度需要增加，则更新：

$$
L \leftarrow N + 1 - L
$$

最终，算法返回能够生成输入序列的最短连接多项式。

## 从 BM 结果恢复 MASK

Berlekamp-Massey 算法返回的连接多项式形式为：

$$
C(x) = 1 + c_1 x + c_2 x^2 + \cdots + c_L x^L
$$

对应递推关系：

$$
s_N + \sum_{i=1}^{L} c_i s_{N-i} = 0
$$

即：

$$
s_N = -\sum_{i=1}^{L} c_i s_{N-i}
$$

令：

$$
N = t + L
$$

则：

$$
s_{t+L} = -\sum_{i=1}^{L} c_i s_{t+L-i}
$$

而题目中的 LFSR 反馈为：

$$
s_{t+L} = \sum_{j=0}^{L-1} m_j s_{t+j}
$$

比较两式可得：

$$
m_j = -c_{L-j} \pmod 3
$$

因此可以从 BM 得到的连接多项式恢复原 LFSR 的 `MASK`。

`solve.py` 中对应的操作为：

```python
rec_mask = [(-conn_poly[L - i] + 3) % 3 for i in range(L)]
```

这一步的本质就是将连接多项式的系数转换成题目 LFSR 使用的反馈掩码形式。

---

## 恢复初始状态

从 `gift` 中恢复出的密钥流前 $L$ 项为：

$$
z_0, z_1, \dots, z_{L-1}
$$

由于 LFSR 的输出就是当前状态的第一个元素，并且每次状态左移一位，因此初始状态正好是：

$$
(z_0, z_1, \dots, z_{L-1})
$$

所以可以用：

- 前 $L$ 个密钥流元素作为初始状态；
- BM 恢复出的 `MASK` 作为反馈掩码；

重新构造一个等价的 LFSR。

需要注意的是，`chall.py` 先加密 `gift`，再继续加密 flag，中间没有重置 LFSR。因此，恢复 LFSR 后必须先消耗掉 `gift` 对应的密钥流长度，把LFSR的内部状态推进到加密 flag 时的状态。

之后生成与 `ct` 等长的密钥流，就可以解密 flag。

当然本题中给出的输出不足以唯一确定最短递推，所以还需要枚举一部分解。详见solve.py