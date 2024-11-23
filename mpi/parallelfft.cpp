#define _USE_MATH_DEFINES

#include <algorithm>
#include <iostream>
#include <unistd.h>
#include <fstream>
#include <iomanip>
#include <chrono>
#include <string>
#include <vector>
#include <mpi.h>
#include <cmath>
#include <unordered_set>

#include "parallelfft.h"
#define ROOT 0

std::tuple<Complex, Complex> butterfly(Complex val1, Complex val2, int k, int N) {
  Complex res1, res2, twiddle;
  twiddle.re = cos(-2 * M_PI * k/N);
  twiddle.im = sin(-2 * M_PI * k/N);
  res1.re = val1.re + twiddle.re * val2.re - twiddle.im * val2.im;
  res1.im = val1.im + twiddle.re * val2.im + twiddle.im * val2.re;
  res2.re = val1.re - twiddle.re * val2.re + twiddle.im * val2.im;
  res2.im = val1.im - twiddle.re * val2.im - twiddle.im * val2.re;

  return std::make_tuple(res1, res2);
}

int computeFFTPosition(int num_points, int pos) {
  int num_bits = log2(num_points);
  int temp = pos;
  int count = 0;
  int ret = 0;

  while (count < num_bits) {
    ret = (ret << 1) + (temp % 2);
    temp = temp >> 1;
    count++;
  }

  return ret;
}

int main(int argc, char *argv[]) {
  const auto init_start = std::chrono::steady_clock::now();
  int pid;
  int nproc;

  // Initialize MPI
  MPI_Init(&argc, &argv);
  // Get process rank
  MPI_Comm_rank(MPI_COMM_WORLD, &pid);
  // Get total number of processes
  MPI_Comm_size(MPI_COMM_WORLD, &nproc);

  int num_points;
  std::string input_filename;

  int opt;
  while ((opt = getopt(argc, argv, "f:p:i:m:b:")) != -1) {
    switch (opt) {
      case 'f':
        input_filename = optarg;
        break;
      default:
        if (pid == ROOT) {
          std::cerr << "Usage: " << argv[0] << " -f input_filename\n";
        }

        MPI_Finalize();
        exit(EXIT_FAILURE);
    }
  }

  std::ifstream fin(input_filename);
  if (!fin) {
    std::cerr << "Unable to open file: " << input_filename << ".\n";
    exit(EXIT_FAILURE);
  }
  fin >> num_points;

  std::vector<Complex> nums;
  nums.resize(num_points);
  for (int i = 0; i < num_points; i++) {
    int rearranged = computeFFTPosition(num_points, i);
    fin >> nums[rearranged].re >> nums[rearranged].im;
  }

  // Random number generator
  num_points = 1048576;
  nums.resize(num_points);
  for (int i = 0; i < num_points; i++) {
    nums[i].re = rand()%20;
    nums[i].im = rand()%20;
  }

  int block_lengths[2] = {1, 1};
  MPI_Datatype types[2] = {MPI_FLOAT, MPI_FLOAT};
  MPI_Aint displacements[2] = {
    offsetof(struct Complex, re),
    offsetof(struct Complex, im)
  };
  MPI_Datatype MPI_Complex;
  MPI_Type_create_struct(2, block_lengths, displacements, types, &MPI_Complex);
  MPI_Type_commit(&MPI_Complex);

  int block_lengths1[2] = {1, 1};
  MPI_Datatype types1[2] = {MPI_INT, MPI_Complex};
  MPI_Aint displacements1[2] = {
    offsetof(struct Complex_arr, idx),
    offsetof(struct Complex_arr, val)
  };
  MPI_Datatype MPI_Complex_arr;
  MPI_Type_create_struct(2, block_lengths1, displacements1, types1, &MPI_Complex_arr);
  MPI_Type_commit(&MPI_Complex_arr);

  // if (pid == ROOT) {
  //   std::cout << "Starting program\n";
  //   printf("Number of points (N): %d\n", num_points);
  //   for (int i = 0; i < num_points; i++) {
  //     printf("point: %f %f\n", nums[i].re, nums[i].im);
  //   }
  // }


  // BEGIN FFT ALGORITHM

  const auto fft_start = std::chrono::steady_clock::now();

  int num_stages = log2(num_points);
  int num_levels = (num_points/2);
  int num_levels_per_proc = num_levels / nproc;
  int start = pid*num_levels_per_proc;

  Complex_arr v1_send, v2_send;
  std::vector<Complex_arr> sends;
  std::vector<Complex_arr> recs;
  sends.resize(2*num_levels_per_proc);
  recs.resize(num_points);

  for (int i = 0; i < num_stages; i++) {
    for (int j = start; j < start+num_levels_per_proc; j++) {
      // compute next stage
      v1_send.idx = ((1 << (i+1)) * (j/(1 << i))) + (j % (1 << i));
      v2_send.idx = v1_send.idx + (1 << i);
      std::tie(v1_send.val, v2_send.val) = butterfly(nums[v1_send.idx], nums[v2_send.idx], (j % (1 << i)), (1 << (i + 1)));
      sends[2*(j-start)] = v1_send;
      sends[2*(j-start) + 1] = v2_send;
    }
    MPI_Allgather(&sends[0], num_points/nproc, MPI_Complex_arr,
                  &recs[0], num_points/nproc, MPI_Complex_arr,
                  MPI_COMM_WORLD);
    for (int j = 0; j < num_points; j++) {
      nums[recs[j].idx] = recs[j].val;
    }
  }

  const auto fft_end = std::chrono::steady_clock::now();

  // END FFT ALGORITHM

  if (pid == ROOT) {
    // for (int i = 0; i < num_points; i++) {
    //   printf("%f %f \n", nums[i].re, nums[i].im);
    // }

    std::cout << "Initialization Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_start - init_start).count() << std::endl;
    std::cout << "Computation Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_end - fft_start).count() << std::endl;
  }

  MPI_Finalize();
}
