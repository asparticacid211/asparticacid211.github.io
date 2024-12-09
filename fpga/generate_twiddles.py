import math
import struct

def negate_string(binstr):
    new_str = ""
    for i in range(len(binstr)):
        if binstr[i] == "1":
            new_str = new_str + "0"
        else:
            new_str = new_str + "1"

    return bin(int(new_str, 2) + 1)[2:]

# takes a float and converts it to a 16 bit fixed point
def float_to_hex(n, fracbits):
    k = n
    k = round(k * math.pow(2, fracbits))

    a = -k if k < 0 else k

    # now convert a (an int) to 16-bit binary
    binstr = "0"
    for i in range(15):
        power = 1 << (14 - i)
        if a >= power:
            binstr = binstr + "1"
            a = a - power
        else:
            binstr = binstr + "0"
    # print("binstr: " + binstr)
    if (k < 0):
        binstr = negate_string(binstr)

    return ('%.*x' % (((len(binstr) + 3) // 4), int('0b'+ binstr, 0))).upper()


def write_twiddles(f, N, fracbits):
    f.write("DEPTH = " + str(N) + ";\n")
    f.write("WIDTH = " + str(32) + ";\n")
    f.write("ADDRESS_RADIX = HEX;\n")
    f.write("DATA_RADIX = HEX;\n\n")
    f.write("CONTENT BEGIN\n\n")

    for i, count in enumerate(range(N)):
        vcos = math.cos(-2 * math.pi * i/N)
        vsin = math.sin(-2 * math.pi * i/N)
        hex1 = float_to_hex(vcos, fracbits)
        hex2 = float_to_hex(vsin, fracbits)
        f.write(f"{i:x}" + " : " + hex1 + hex2 + ";\n")

    f.write("END;\n")

f = open("twiddle_factors.mif", "w")
write_twiddles(f, 8, 8)
f.close()