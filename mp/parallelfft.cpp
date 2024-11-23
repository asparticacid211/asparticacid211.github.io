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
  int num_threads;

  int num_points;
  std::string input_filename;

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
  num_points = 1024;
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
  for (i = 0; i < num_stages; i++) {
    #pragma omp parallel for default(none) shared(i, nums, num_levels) private(j, idx1, idx2, v1, v2) schedule(dynamic)
    for (j = 0; j < num_levels; j++) {
      // compute next stage
      idx1 = ((1 << (i+1)) * (j/(1 << i))) + (j % (1 << i));
      idx2 = idx1 + (1 << i);
      std::tie(v1, v2) = butterfly(nums[idx1], nums[idx2], (j % (1 << i)), (1 << (i + 1)));
      nums[idx1] = v1;
      nums[idx2] = v2;
    }
  }

  const auto fft_end = std::chrono::steady_clock::now();

  // END FFT ALGORITHM

  // for (int i = 0; i < num_points; i++) {
  //   printf("%f %f \n", nums[i].re, nums[i].im);
  // }

  std::cout << "Initialization Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_start - init_start).count() << std::endl;
  std::cout << "Computation Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_end - fft_start).count() << std::endl;
}
