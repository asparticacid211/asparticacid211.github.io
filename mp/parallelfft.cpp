#define _USE_MATH_DEFINES

#include <algorithm>
#include <iostream>
#include <unistd.h>
#include <fstream>
#include <iomanip>
#include <chrono>
#include <string>
#include <vector>
#include <omp.h>
#include <cmath>
#include <unordered_set>

#include "parallelfft.h"
#define ROOT 0
#define MIN_SIZE 1000

// computes val1 + val2 * twiddle (determined by k, N) and val1 - val2 * twiddle
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

// recursive fft algorithm (fastest sequential solution)
void fft_recursion(Complex *arr, int N, int s) {
  if (N == 1) {
    return;
  }

  fft_recursion(&arr[0], N/2, 2*s);
  fft_recursion(&arr[1], N/2, 2*s);

  for (int k = 0; k < N/2; k++) {
    std::tie(arr[k], arr[k+N/2]) = butterfly(arr[k], arr[k+N/2], k, N);
  }
}

// compute the bit-reversed position for a given bit position
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
  int num_threads;

  int num_points;
  std::string input_filename;

  // read arguments
  int opt;
  while ((opt = getopt(argc, argv, "f:n:")) != -1) {
    switch (opt) {
      case 'f':
        input_filename = optarg;
        break;
      case 'n':
        num_threads = atoi(optarg);
        break;
      default:
        num_threads = 8;
        std::cerr << "Usage: " << argv[0] << " -f input_filename -n num_threads \n";

        exit(EXIT_FAILURE);
    }
  }

  // open file and read N
  std::ifstream fin(input_filename);
  if (!fin) {
    std::cerr << "Unable to open file: " << input_filename << ".\n";
    exit(EXIT_FAILURE);
  }
  fin >> num_points;

  // read the points in the file
  std::vector<Complex> nums;
  nums.resize(num_points);
  for (int i = 0; i < num_points; i++) {
    int rearranged = computeFFTPosition(num_points, i);
    fin >> nums[rearranged].re >> nums[rearranged].im;
  }


  // random number generator (overrides data read above)
  num_points = 1 << 20;
  nums.resize(num_points);
  for (int i = 0; i < num_points; i++) {
    nums[i].re = rand()%20;
    nums[i].im = rand()%20;
  }


  // std::cout << "Starting program\n";
  // printf("Number of points (N): %d\n", num_points);
  // for (int i = 0; i < num_points; i++) {
  //   printf("point: %f %f\n", nums[i].re, nums[i].im);
  // }

  // BEGIN FFT ALGORITHM
  omp_set_num_threads(num_threads);
  const auto fft_start = std::chrono::steady_clock::now();

  int num_stages = log2(num_points);
  int num_levels = (num_points/2);
  Complex v1, v2;
  int i, j, idx1, idx2;
  // we compute the fft in a series of stages
  // in each stage, we have to perform several (independent) butterflys
  // thus, we can split these equally across the processors
  for (i = 0; i < num_stages; i++) {
    #pragma omp parallel for default(none) shared(i, nums, num_levels, num_threads) private(j, idx1, idx2, v1, v2) schedule(static, 1)
    for (j = 0; j < num_levels; j++) {
      // compute the two array element indices, and then butterfly them
      idx1 = ((1 << (i+1)) * (j/(1 << i))) + (j % (1 << i));
      idx2 = idx1 + (1 << i);
      std::tie(v1, v2) = butterfly(nums[idx1], nums[idx2], (j % (1 << i)), (1 << (i + 1)));
      nums[idx1] = v1;
      nums[idx2] = v2;
    }
  }

  const auto fft_end = std::chrono::steady_clock::now();

  // END FFT ALGORITHM

  /*
  // BEGIN FFT ALGORITHM (RECURSION)
  const auto fft_start = std::chrono::steady_clock::now();
  fft_recursion(&nums[0], num_points, 1);
  const auto fft_end = std::chrono::steady_clock::now();
  // END FFT ALGORITHM (RECURSION)
  */

  // print output values if we want
  // for (int i = 0; i < num_points; i++) {
  //   printf("%f %f \n", nums[i].re, nums[i].im);
  // }

  // print times
  std::cout << "Initialization Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_start - init_start).count() << std::endl;
  std::cout << "Computation Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_end - fft_start).count() << std::endl;
}
