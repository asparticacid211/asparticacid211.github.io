# [PROJECT NAME]
URL: asparticacid211.github.io  
Team members: Lohith Tummala (lctummal), Kavish Purani (kpurani)
## Summary
...
## Background
...
## Challenges
...
## Resources
...
## Goals
### What we plan to achieve
* C++ MPI version of the FFT algorithm
* 8-point FPGA version of the FFT algorithm
* Speedup graphs of MPI (and FPGA? how does that work?)
### What we hope to achieve
* A generalized (N-point) implementation on FPGA
* ...
## Platform
The devices that we plan to implement this algorithm on are the DE2-115 Altera FPGA and the GHC machines. When we code up the algorithm on the GHC machines, we plan to use the C++ programming language with the OpenMPI language construct. This is because the FFT algorithm is highly recursive, so the process of splitting data and recombining makes the message-passing idea quite intuitive to implement. The GHC machines also have 8 cores, which is why we start off with developing an 8-point algorithm.  
  
As for the FPGA, we intend to use SystemVerilog, a hardware descriptive language designed to write code that can be transformed into utilization of physical logic gates and blocks on the FPGA. We use the DE2-115 FPGA since we have used it for 18-240, thus making it the most accessible device for us.
## Schedule
November 10-16: Develop strategies for MPI and FPGA implementations  
November 17-23: Code the MPI version and benchmark results, start FPGA implementation (for 8 points)  
November 24-30: Finish 8-point FPGA implemtation, benchmark results  
December 1-7: ...  
December 8-13: Write final paper and poster, work on generalized point algorithm if time permits  
## Link to Writeup
...
