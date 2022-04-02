
#include <benchmark/benchmark.h>

#include <vector>
#include <cstring>

/// Size of IPv4 address (in bytes).
static constexpr size_t ADDR_IPV4_SIZE = 4;

/// Size of IPv6 address (in bytes).
static constexpr size_t ADDR_IPV6_SIZE = 16;

class CNetAddr {
public:
    std::vector<uint8_t> m_addr{ADDR_IPV6_SIZE, 0};
};

class CSubNet {
public:
    /// Network (base) address
    CNetAddr network;
    /// Netmask, in network byte order
    uint8_t netmask[16];
    /// Is this value valid? (only used to signal parse errors)
    bool valid;


    CSubNet():
        valid(false)
    {
        memset(netmask, 0, sizeof(netmask));
    }

    CSubNet(const CNetAddr& addr, uint8_t mask) : CSubNet()
    {
        if (mask > ADDR_IPV6_SIZE * 8) {
            return;
        }

        network = addr;

        uint8_t n = mask;
        for (size_t i = 0; i < network.m_addr.size(); ++i) {
            const uint8_t bits = n < 8 ? n : 8;
            netmask[i] = (uint8_t)((uint8_t)0xFF << (8 - bits)); // Set first bits.
            network.m_addr[i] &= netmask[i]; // Normalize network according to netmask.
            n -= bits;
        }
    }
};

class opt_CNetAddr {
public:
    std::vector<char8_t> m_addr{ADDR_IPV6_SIZE, 0};
};

class opt_CSubNet {
public:
    /// Network (base) address
    opt_CNetAddr network;
    /// Netmask, in network byte order
    char8_t netmask[16];
    /// Is this value valid? (only used to signal parse errors)
    bool valid;


    opt_CSubNet():
        valid(false)
    {
        memset(netmask, 0, sizeof(netmask));
    }

    opt_CSubNet(const opt_CNetAddr& addr, char8_t mask) : opt_CSubNet()
    {
        if (mask > ADDR_IPV6_SIZE * 8) {
            return;
        }

        network = addr;

        char8_t n = mask;
        for (size_t i = 0; i < network.m_addr.size(); ++i) {
            const char8_t bits = n < 8 ? n : 8;
            netmask[i] = (char8_t)((char8_t)0xFF << (8 - bits)); // Set first bits.
            network.m_addr[i] &= netmask[i]; // Normalize network according to netmask.
            n -= bits;
        }
    }
};

static void original(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    for (size_t i = 0; i < 2 << 26; ++i) {
        CNetAddr cnetaddr;
        for (size_t j = 0; j < ADDR_IPV6_SIZE; ++j) {
            cnetaddr.m_addr[j]= 0xff;
        }
        CSubNet csubnet(cnetaddr, 127);
        benchmark::DoNotOptimize(csubnet);
    }
  }
}
BENCHMARK(original);

static void optimised(benchmark::State& state) {
  // Code inside this loop is measured repeatedly
  for (auto _ : state) {
    for (size_t i = 0; i < 2 << 26; ++i) {
        opt_CNetAddr cnetaddr;
        for (size_t j = 0; j < ADDR_IPV6_SIZE; ++j) {
            cnetaddr.m_addr[j]= 0xff;
        }
        opt_CSubNet csubnet(cnetaddr, 127);
        benchmark::DoNotOptimize(csubnet);
    }
  }
}
BENCHMARK(optimised);