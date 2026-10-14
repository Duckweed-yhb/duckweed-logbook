class myBlock:
  ROUNDS = 4
  BLOCK_SIZE = 4
  KEY_SIZE = 16

  def __init__(self, sbox: list[int], key: bytes):
    key_padding = lambda k: (k + b"\x00" * (self.KEY_SIZE - len(k) % self.KEY_SIZE))  # noqa: E731
    self.key: bytes = key_padding(key)[: self.KEY_SIZE]
    # fmt: off
    self.SBOX = sbox
    # fmt: on
    self.skey = [
      self.key[i : i + self.BLOCK_SIZE]
      for i in range(0, len(self.key), self.BLOCK_SIZE)
    ]
    assert len(self.skey) == self.ROUNDS

  def block_enc(self, block: bytes) -> bytes:
    assert len(block) == self.BLOCK_SIZE
    state = list(block)
    for round in range(self.ROUNDS):
      for idx in range(self.BLOCK_SIZE):
        state[idx] ^= self.skey[round][idx]
        state[idx] = self.SBOX[state[idx]]
    return bytes(state)


class myStream:
  def __init__(self, sbox: list[int], key: bytes, nonce: bytes):
    self.block_cipher = myBlock(sbox, key)
    self.nonce = nonce

  def get_stream(self, length: int) -> bytes:
    stream = b""
    while len(stream) < length:
      stream += self.block_cipher.block_enc(self.nonce)
      self.nonce = self.block_cipher.block_enc(self.nonce)
    return stream[:length]

  def enc(self, data: bytes) -> bytes:
    stream = self.get_stream(len(data))
    return bytes([data[i] ^ stream[i] for i in range(len(data))])
