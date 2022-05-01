// From bitcoin src/i2p.cpp
#include <benchmark/benchmark.h>

#include <vector>

std::string orig_SwapBase64(const std::string& from)
{
    std::string to;
    to.resize(from.size());
    for (size_t i = 0; i < from.size(); ++i) {
        switch (from[i]) {
        case '-':
            to[i] = '+';
            break;
        case '~':
            to[i] = '/';
            break;
        case '+':
            to[i] = '-';
            break;
        case '/':
            to[i] = '~';
            break;
        default:
            to[i] = from[i];
            break;
        }
    }
    return to;
}

std::u8string opt_SwapBase64(const std::u8string& from)
{
    std::u8string to;
    to.resize(from.size());
    for (size_t i = 0; i < from.size(); ++i) {
        switch (from[i]) {
        case '-':
            to[i] = '+';
            break;
        case '~':
            to[i] = '/';
            break;
        case '+':
            to[i] = '-';
            break;
        case '/':
            to[i] = '~';
            break;
        default:
            to[i] = from[i];
            break;
        }
    }
    return to;
}

static void optimised(benchmark::State& state) {
  auto s = std::u8string(state.range(0), 'A');
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = opt_SwapBase64(s);
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(optimised)->RangeMultiplier(2)->Range(8, 8<<21);

static void original(benchmark::State& state) {
  auto s = std::string(state.range(0), 'A');
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = orig_SwapBase64(s);
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(original)->RangeMultiplier(2)->Range(8, 8<<21);

/*
static void original_vec(benchmark::State& state) {
  auto s = std::string(state.range(0), 'A');
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = orig_vec(s);
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(original_vec)->RangeMultiplier(2)->Range(8, 8<<21);
*/