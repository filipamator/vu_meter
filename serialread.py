import serial
import time
ser = serial.Serial('COM5', 4*115200, timeout=1)

buffer = bytearray([])
sample = bytearray([])
counter = 0

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val 

ser.reset_input_buffer()

while counter<2048:
  bufflen = ser.in_waiting
  if bufflen > 0:
    buffer =  ser.read(bufflen)
    sample = sample + buffer
    counter = counter + len(buffer)
    time.sleep(0.05)


#print(len(buffer))
size = len(sample)/2
for x in range(0, int(size) ):
  value = 256*sample[2*x] + sample[2*x+1]
  value = twos_comp(value,16)
  print(str(x) + " " + str(value))



#print(buffer[0])
  