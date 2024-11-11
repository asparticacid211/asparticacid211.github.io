# [PROJECT NAME]
URL: asparticacid211.github.io  
Team members: Lohith Tummala (lctummal), Kavish Purani (kpurani)
## Summary
We plan to implement a parallel version of the Cooley-Tuley Radix-2 Fast Fourier Transform algorithm using SystemVerilog and synthesized on the DE2-115 FPGA, initially for 8 points. We want to assess the latency of the computation and the logic utilization on the FPGA as a function of the number of points that we decide to compute the FFT for. We also wish to compare this implementation against an OpenMPI C++ implementation that will be run on the GHC 8-core computers.  
## Background
...
## Challenges
...
## Resources
[Here](https://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf) is a link to the user manual for the DE2-115 FPGA. We plan to use this to find out how to leverage certain logic/memory blocks for our algorithm.
## Goals
### What we plan to achieve
* C++ MPI version of the FFT algorithm
* 8-point FPGA version of the FFT algorithm
* Speedup graphs of MPI (and FPGA? how does that work?)
### What we hope to achieve
* A generalized (N-point) implementation on FPGA (N is a power of 2)
* A version of the above but N is not a power of 2   
## Platform
The devices that we plan to implement this algorithm on are the DE2-115 Altera FPGA and the GHC machines. When we code up the algorithm on the GHC machines, we plan to use the C++ programming language with the OpenMPI language construct. This is because the FFT algorithm is highly recursive, so the process of splitting data and recombining makes the message-passing idea quite intuitive to implement. The GHC machines also have 8 cores, which is why we start off with developing an 8-point algorithm.  
  
As for the FPGA, we intend to use SystemVerilog, a hardware descriptive language designed to write code that can be transformed into utilization of physical logic gates and blocks on the FPGA. We use the DE2-115 FPGA since we have used it for 18-240, thus making it the most accessible device for us.
## Schedule
November 10-16: Develop strategies for MPI and FPGA implementations  
November 17-23: Code the MPI version and benchmark results, start FPGA implementation (for 8 points)  
November 24-30: Finish 8-point FPGA implemtation, benchmark results (?)  
December 1-7: ...(?)  
December 8-13: Write final paper and poster, work on generalized point algorithm if time permits  
## Link to Writeup
...
