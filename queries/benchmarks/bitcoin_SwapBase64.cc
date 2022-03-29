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

std::vector<uint8_t> orig_vec(const std::string& from)
{
    std::vector<uint8_t> to;
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
    #pragma clang loop unroll(disable)
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
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = opt_SwapBase64(std::u8string(state.range(0), 'A'));
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(optimised)->RangeMultiplier(2)->Range(8, 8<<21);

static void original(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = orig_SwapBase64(std::string(state.range(0), 'A'));
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(original)->RangeMultiplier(2)->Range(8, 8<<21);

static void original_vec(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = orig_vec(std::string(state.range(0), 'A'));
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(original_vec)->RangeMultiplier(2)->Range(8, 8<<21);