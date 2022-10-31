#!/usr/bin/python3

from Crypto.Cipher import AES
import binascii
import base64

key = base64.b64decode('GiwqC0SnH+qmndq/')
passphrase='0lymp_sp0ke'
data = binascii.unhexlify('9012a33bfb0a51dec4f96404cdd7300ec6afca1fa0d6679a7c036652d014a38faf909e9c44d08dffac121aa85d48b7256fa74542e2545e27dc070adfc03af26f2a32f50c2c311d5c91ff6de2ca3b4347da70669575c9b198f4')
nonce, tag = data[:12], data[-16:]
cipher = AES.new('GiwqC0SnH+qmndq/', AES.MODE_GCM, nonce)
print(cipher.decrypt_and_verify('IkGevjzhfpcoYeYZF2hfTRt8N4bxGL0JI1MA6tnjXVn+7vhQVh+UhxXz9LRf0UMUM2V0eA==', tag))
