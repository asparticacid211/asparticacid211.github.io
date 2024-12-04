def write_twiddles(f, N):
    f.write("000010021")

f = open("/Users/kavishpurani/Desktop/15618/asparticacid211.github.io/fpga/the_twiddle_factors.mem", "w")
write_twiddles(f, 8)