#include <benchmark/benchmark.h>

#include <stdlib.h>
#include <stdint.h>
#include <vector> 

struct key_orig {                                                                    
    unsigned char & operator[](int i) {                                               
        return bytes[i];                                                        
    }                                                                           
    unsigned char operator[](int i) const {                                           
        return bytes[i];                                                        
    }                                                                           
    unsigned char bytes[32];                                                          
};

typedef std::vector<key_orig> keyV_orig;

static const key_orig Z_orig = { {0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00,     0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00  } };

keyV_orig bulletproof_PROVE_orig(const std::vector<uint64_t> &v)
{                                                                                    
                                                                                
  keyV_orig sv(v.size());                                                            
  for (size_t i = 0; i < v.size(); ++i)                                              
  {                                                                                  
    sv[i] = Z_orig;                                                             
    sv[i].bytes[0] = v[i] & 255;                                                     
    sv[i].bytes[1] = (v[i] >> 8) & 255;                                              
    sv[i].bytes[2] = (v[i] >> 16) & 255;                                             
    sv[i].bytes[3] = (v[i] >> 24) & 255;                                             
    sv[i].bytes[4] = (v[i] >> 32) & 255;                                             
    sv[i].bytes[5] = (v[i] >> 40) & 255;                                             
    sv[i].bytes[6] = (v[i] >> 48) & 255;                                             
    sv[i].bytes[7] = (v[i] >> 56) & 255;                                             
  }                                                                                  

   return sv;
}   

struct key {                                                                    
    char8_t & operator[](int i) {                                               
        return bytes[i];                                                        
    }                                                                           
    char8_t operator[](int i) const {                                           
        return bytes[i];                                                        
    }                                                                           
    char8_t bytes[32];                                                          
};

typedef std::vector<key> keyV;

static const key Z = { {0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00,     0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00 , 0x00, 0x00, 0x00,0x00  } };

keyV bulletproof_PROVE(const std::vector<uint64_t> &v)
{                                                                                                                                                                  
  keyV sv(v.size());                                                            
  for (size_t i = 0; i < v.size(); ++i)                                              
  {                                                                                  
    sv[i] = Z;                                                             
    sv[i].bytes[0] = v[i] & 255;                                                     
    sv[i].bytes[1] = (v[i] >> 8) & 255;                                              
    sv[i].bytes[2] = (v[i] >> 16) & 255;                                             
    sv[i].bytes[3] = (v[i] >> 24) & 255;                                             
    sv[i].bytes[4] = (v[i] >> 32) & 255;                                             
    sv[i].bytes[5] = (v[i] >> 40) & 255;                                             
    sv[i].bytes[6] = (v[i] >> 48) & 255;                                             
    sv[i].bytes[7] = (v[i] >> 56) & 255;                                             
  }                                                                                  

   return sv;
}


static void optimised(benchmark::State& state) {
  std::vector<uint64_t> v(state.range(0));
  std::fill(v.begin(), v.end(), 255);
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = bulletproof_PROVE(v);
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(optimised)->RangeMultiplier(2)->Range(2<<6, 2<<14);

static void original(benchmark::State& state) {
  std::vector<uint64_t> v(state.range(0));
  std::fill(v.begin(), v.end(), 255);
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    auto r = bulletproof_PROVE_orig(v);
    // Make sure the variable is not optimized away by compiler
    benchmark::DoNotOptimize(r);
  }
}
// Register the function as a benchmark
BENCHMARK(original)->RangeMultiplier(2)->Range(2<<6, 2<<14);