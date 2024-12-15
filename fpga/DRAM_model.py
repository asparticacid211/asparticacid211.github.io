
import math
import numpy as np

def dram_manager(dict, addr1, addr2, cycle_count, act_row, prev_return):
    addr1_row = addr1 % 2048 
    addr2_row = addr2 % 2048 
    start_addr1 = addr1
    start_addr2 = addr2
    if (dict.get(addr1) != None and dict.get(addr2) != None):
        prev_return += 1
    elif (dict.get(addr2) != None):
        if (addr1_row == act_row):
            cycle_count += 3
        else:
            cycle_count += 9
            act_row = addr1_row
        for i in range(8):
            dict[start_addr1+i] = 1
        prev_return = 0
    elif (dict.get(addr1) != None):
        if (addr2_row == act_row):
            cycle_count += 3
        else:
            cycle_count += 9
            act_row = addr2_row
        for i in range(8):
            dict[start_addr2+i] = 1
        prev_return = 0
    else:
        if (addr1 == act_row):
            cycle_count += 3
            if (addr2_row == act_row):
                cycle_count += 3
            else:
                cycle_count += 9
                act_row = addr2_row
        else:
            if (addr2_row == act_row):
                cycle_count += 3
            else:
                cycle_count += 9
                act_row = addr2_row
            if (addr1_row == act_row):
                cycle_count += 3
            else:
                cycle_count += 9
                act_row = addr1_row
        for i in range(8):
            dict[start_addr1+i] = 1
            dict[start_addr2+i] = 1
        prev_return = 0
    
    over = len(dict) - 128
    while (over > 0):
        dict.pop(next(iter(dict)))
        over -= 1
    return [dict, cycle_count, act_row, prev_return]


# Change the input size below
N = 1 << 25
print("Aprroximating Cycles for Input Size: " + str(N))
cycle_count = 0
stages = int(math.log2(N))
levels = int(N/2)
for i in range(stages):
    j = 0
    dict = {}
    act_row = 0
    prev_return = 0
    vals = [dict, cycle_count, act_row, prev_return]
    for k in range(levels):
        if (k == levels-1):
            j = levels-1
        addr1 = (((j << 1) << i) | ((j << 1) >> (stages-i))) & (N-1)
        addr2 = ((((j<<1)+1) << i) | (((j<<1)+1) >> (stages-i))) & (N-1)
        j = (j + (levels >> i)) % (levels-1)

        vals = dram_manager(vals[0], addr1, addr2, vals[1], vals[2], vals[3])
        vals[1] += 1
    cycle_count = vals[1]

print(cycle_count)



