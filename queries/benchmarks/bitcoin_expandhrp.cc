#include <benchmark/benchmark.h>

#include <vector>
#include <stdint.h>
#include <string>

typedef std::vector<uint8_t> data;
typedef std::vector<char8_t> data2;

data orig_ExpandHRP(const std::string& hrp)
{
    data ret;
    ret.reserve(hrp.size() + 90);
    ret.resize(hrp.size() * 2 + 1);
    for (size_t i = 0; i < hrp.size(); ++i) {
        unsigned char c = hrp[i];
        ret[i] = c >> 5;
        ret[i + hrp.size() + 1] = c & 0x1f;
    }
    ret[hrp.size()] = 0;
    return ret;
}

data2 opt_ExpandHRP(const std::string& hrp)
{
    data2 ret;
    ret.reserve(hrp.size() + 90);
    ret.resize(hrp.size() * 2 + 1);
    for (size_t i = 0; i < hrp.size(); ++i) {
        unsigned char c = hrp[i];
        ret[i] = c >> 5;
        ret[i + hrp.size() + 1] = c & 0x1f;
    }
    ret[hrp.size()] = 0;
    return ret;
}

static void optWrapper(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto created_string = opt_ExpandHRP(std::string(state.range(0), 'A'));
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(created_string);
  }
}
// Register the function as a benchmark
BENCHMARK(optWrapper)->RangeMultiplier(2)->Range(8, 8<<12);

static void origWrapper(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto created_string = orig_ExpandHRP(std::string(state.range(0), 'A'));
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(created_string);
  }
}
// Register the function as a benchmark
BENCHMARK(origWrapper)->RangeMultiplier(2)->Range(8, 8<<12);