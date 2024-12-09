import math

def print_conversion(hexa, frac):
    hex1 = hexa[:4]
    hex2 = hexa[4:]

    bin1 = format(int(hex1, 16), '0>16b')
    bin2 = format(int(hex2, 16), '0>16b')

    dec1 = int(bin1[1:], 2)
    dec2 = int(bin2[1:], 2)

    if (bin1[0] == "1"):
        dec1 -= math.pow(2, 15)
    if (bin2[0] == "1"):
        dec2 -= math.pow(2, 15)

    dec1 = dec1 / math.pow(2, frac)
    dec2 = dec2 / math.pow(2, frac)

    print(f"{dec1} {dec2}")

f = open("outputs.mem", "r")
lines = f.readlines()
for i in lines:
    print_conversion(i, 8)