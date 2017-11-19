import math
import random

tau = 1/48000
f1 = 7000
a1 = 16384

f2 =8000
a2 = 8192

for i in range(0,8192):
    sample = a1*math.sin(2*3.141592*f1 * i * tau) # + a2*math.sin(2*3.141592*f2 * i * tau)
    print(int(sample))
