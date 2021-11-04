// This file contains examples that do NOT have the sorts of aliasing issues
// that force the compiler to generate extra loads from memory.

#include <stddef.h>

#include <cstdint>
#include <vector>

#include "aetypes.h"

// From https://travisdowns.github.io/blog/2019/08/26/vector-inc.html
// No aliasing issues as the vector is of type uint32_t
void vector32_inc(std::vector<uint32_t> &v) {
    for (size_t i = 0; i < v.size(); i++) {
        v[i]++;
    }
}

// From PHP ext/fileinfo/libmagic/cdf.c
// No aliasing issues as `buf`, `len` and `p` are passed on the stack and the
// write through `buf` cannot alias any relevant data
char *cdf_u16tos8(char *buf, size_t len, const uint16_t *p) {
    size_t i;
    for (i = 0; i < len && p[i]; i++) buf[i] = (char)p[i];
    buf[i] = '\0';
    return buf;
}

// Inspired by K2 src/isa/ebpf/inst_var.cc
// https://github.com/SeanHeelan/superopt/blob/407eb410466e1a21d081e96cc803ea6a59aa7e7e/src/isa/ebpf/inst_var.cc#L1251
// There are no aliasing issues as the vectors are of uint32_t
void init_safety_chk32(const std::vector<uint32_t> &reg_in, std::vector<uint32_t> &reg_out) {
    for (int i = 0; i < reg_out.size(); ++i) {
        reg_out[i] = reg_in[i];
    }
}

// This inner loop of this function does not have the same issue as found in its
// companion function in positive.cpp as the row pointer is stored in a local
// variable before entering the inner loop.
void write2d_noalias(char **buf, size_t x, size_t y) {
    for (size_t i = 0; i < y; ++i) {
        char *tmp = buf[i];
        for (size_t j = 0; j < x; ++j) {
            tmp[j] = 0;
        }
    }
}

// This function is different to its variant in the positive examples in that the
// write through the character pointer has been lifted out of the loop. As a result,
// the compiler can generate code to load the int pointer once, then produce an optimised
// loop body.
void write_through_struct_noalias(char *buf, PointerHolder *ptr, int y, size_t cnt) {
    *(ptr->x) = 0;
    buf[0] = 'A';
    for (size_t i = 0; i < cnt; ++i) {
        *(ptr->x) += i;
    }
}
