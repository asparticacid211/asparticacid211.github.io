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
  printf("num_threads: %d\n", omp_get_num_threads());
  printf("NUM_threads: %d\n", num_threads);
  printf("numprocs: %d\n", omp_get_num_procs());
  const auto fft_start = std::chrono::steady_clock::now();

  int num_stages = log2(num_points);
  int num_levels = (num_points/2);
  int count0;
  int count1;
  int count2;
  int count3;
  int count4;
  int count5;
  int count6;
  int count7;
  double stage_sum = 0;
  Complex v1, v2;
  int i, j, idx1, idx2;
  for (i = 0; i < num_stages; i++) {
    double stage_start = omp_get_wtime();
    count0 = 0;
    count1 = 0;
    count2 = 0;
    count3 = 0;
    count4 = 0;
    count5 = 0;
    count6 = 0;
    count7 = 0;
    // double wtime = omp_get_wtime();
    // printf("num_threads: %d\n", omp_get_num_threads());
    #pragma omp parallel for default(none) shared(i, nums, num_levels, num_threads, count0, count1, count2, count3, count4, count5, count6, count7) private(j, idx1, idx2, v1, v2) schedule(static, 1)
    for (j = 0; j < num_levels; j++) {
      // compute next stage
      double start = omp_get_wtime();
      idx1 = ((1 << (i+1)) * (j/(1 << i))) + (j % (1 << i));
      idx2 = idx1 + (1 << i);
      std::tie(v1, v2) = butterfly(nums[idx1], nums[idx2], (j % (1 << i)), (1 << (i + 1)));
      nums[idx1] = v1;
      nums[idx2] = v2;
      // double end = omp_get_wtime();
      if (omp_get_thread_num() == 0) count0++;
      else if (omp_get_thread_num() == 1) count1++;
      else if (omp_get_thread_num() == 2) count2++;
      else if (omp_get_thread_num() == 3) count3++;
      else if (omp_get_thread_num() == 4) count4++;
      else if (omp_get_thread_num() == 5) count5++;
      else if (omp_get_thread_num() == 6) count6++;
      else count7++;
      double end = omp_get_wtime();
      // printf("num_threads: %d\n", omp_get_num_threads());
      // printf("time %d: %.8f\n", omp_get_thread_num(), end - start);
    }
    // wtime = omp_get_wtime() - wtime;
    // printf( "Time taken by thread %d is %f\n", omp_get_thread_num(), wtime );
    double stage_elapsed = omp_get_wtime() - stage_start;
    printf("stage %d time: %f\n", i, stage_elapsed);
    /*
    printf("count0: %d\n", count0);
    printf("count1: %d\n", count1);
    printf("count2: %d\n", count2);
    printf("count3: %d\n", count3);
    printf("count4: %d\n", count4);
    printf("count5: %d\n", count5);
    printf("count6: %d\n", count6);
    printf("count7: %d\n", count7);
    */
    // double stage_elapsed = omp_get_wtime() - stage_start;
    // printf("stage %d time: %f\n", i, stage_elapsed);
    stage_sum += stage_elapsed;
  }


  const auto fft_end = std::chrono::steady_clock::now();

  printf("stage sum: %f\n", stage_sum);
  printf("stage avg: %f\n", stage_sum/num_stages);
  // END FFT ALGORITHM

  // for (int i = 0; i < num_points; i++) {
  //   printf("%f %f \n", nums[i].re, nums[i].im);
  // }

  std::cout << "Initialization Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_start - init_start).count() << std::endl;
  std::cout << "Computation Time (sec): " << std::fixed << std::setprecision(10) << std::chrono::duration_cast<std::chrono::duration<double>>(fft_end - fft_start).count() << std::endl;
}
