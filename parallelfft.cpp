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

void butterfly(std::vector<Complex> &array, int index1, int index2, int k, int N) {
  Complex val1, val2, res1, res2, twiddle;
  val1 = array[index1];
  val2 = array[index2];
  twiddle.re = cos(-2 * M_PI * k/N);
  twiddle.im = sin(-2 * M_PI * k/N);
  res1.re = val1.re + twiddle.re * val2.re - twiddle.im * val2.im;
  res1.im = val1.im + twiddle.re * val2.im + twiddle.im * val2.re;
  res2.re = val1.re - twiddle.re * val2.re + twiddle.im * val2.im;
  res2.im = val1.im - twiddle.re * val2.im - twiddle.im * val2.re;

  array[index1] = res1;
  array[index2] = res2;
}

int main(int argc, char *argv[]) {
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


  std::vector<Complex> nums;

  std::ifstream fin(input_filename);
  if (!fin) {
    std::cerr << "Unable to open file: " << input_filename << ".\n";
    exit(EXIT_FAILURE);
  }

  fin >> num_points;

  nums.resize(num_points);
  if (num_points == 8) {
    fin >> nums[0].re >> nums[0].im;
    fin >> nums[4].re >> nums[4].im;
    fin >> nums[2].re >> nums[2].im;
    fin >> nums[6].re >> nums[6].im;
    fin >> nums[1].re >> nums[1].im;
    fin >> nums[5].re >> nums[5].im;
    fin >> nums[3].re >> nums[3].im;
    fin >> nums[7].re >> nums[7].im;
  }
  /*
  for (auto& num : nums) {
    fin >> num.re >> num.im;
  }
  */

  int block_lengths[2] = {1, 1};
  MPI_Datatype types[2] = {MPI_FLOAT, MPI_FLOAT};
  MPI_Aint displacements[2] = {
    offsetof(struct Complex, re),
    offsetof(struct Complex, im)
  };
  MPI_Datatype MPI_Complex;
  MPI_Type_create_struct(2, block_lengths, displacements, types, &MPI_Complex);
  MPI_Type_commit(&MPI_Complex);

  if (pid == ROOT) std::cout << "Starting program\n";

  printf("Number of points (N): %d\n", num_points);


  if (pid == ROOT) {
    for (int i = 0; i < num_points; i++) {
      printf("point: %f %f\n", nums[i].re, nums[i].im);
    }
  }


  // BEGIN FFT ALGORITHM

  int index1, index2;
  int num_stages = log2(num_points);
  for (int i = 0; i < num_stages; i++) {
    for (int j = 0; j < num_points/2; j++) {
      // compute next stage
      index1 = ((1 << (i+1)) * (j/(1 << i))) + (j % (1 << i));
      index2 = index1 + (1 << i);
      printf("index1: %d, index2: %d\n", index1, index2);
      butterfly(nums, index1, index2, (j % (1 << i)), (1 << (i + 1)));
    }
  }

  for (int i = 0; i < num_points; i++) {
    printf("%f %f \n", nums[i].re, nums[i].im);
  }

  // END FFT ALGORITHM

  MPI_Finalize();
}
