# %%
import secp256k1
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
pub_address = 0x000000097c7e6f43bb3f225db275b22c666402f1
x_q = 0x4dd42356847875c8ae9fb131edaf9b823f63d6c00b850d678285e4f8eb403b7b
y_q = 0x4fc3da7548f9ffd09259f29cbf41b5e1daa0f83dcf02fa8dd3cd42647b6606cf
assert p == 2**256 - 2**32 - 2**9 - 2**8 - 2**7 - 2**6 - 2**4 - 1

# %%
def pow(i, n, p):
  s = 1
  while n > 0:
    if n % 2 == 1:
      s = (s * i) % p
    i = (i * i) % p
    n //= 2
  return s
def add(x_1, y_1, x_2, y_2, p):
  if (x_1 - x_2) % p == 0:
    if (y_1 + y_2) % p == 0:
      return None
    s = ((3*x_1*x_1)%p)*pow(2*y_1,p-2,p)%p
  else:
    s = (y_1 - y_2) * pow(x_1-x_2,p-2,p)%p
  x_r = (s*s - x_1 - x_2) % p
  y_r = (y_1 + s*(x_r-x_1)) % p
  return x_r, p-y_r
def get_k(x_q, y_q, k, p, n):
  x_k, y_k = x_q, y_q
  for i in range(k-1):
    x_k, y_k = add(x_k, y_k, x_q, y_q, p)
  s = pow(k, n-2, n) * x_k % n
  v = y_k % 2
  if s > n/2:
    s = n-s
    v = 1-v
  print('0x%.64x%.64x%x' % (x_k, s, 27+v))
  return v, x_k, s

def check(v, r, s, x_q, y_q):
  ecdsa = secp256k1.ECDSA()
  sig = ecdsa.ecdsa_recoverable_deserialize(bytes.fromhex("%.64x%.64x" %(r,s)), v)
  pubkey = ecdsa.ecdsa_recover(bytes.fromhex("0"*64), sig, raw=True)
  pubkey = secp256k1.PublicKey(pubkey).serialize(False)[1:]
  return pubkey.hex() == "%.64x%.64x" % (x_q, y_q)

# %%
assert pow(x_q,3,p)+7 == pow(y_q,2,p)
for k in range(2, 6):
  assert check(*get_k(x_q, y_q, k, p, n), x_q, y_q)
