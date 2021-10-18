// This file contains examples that have the sorts of aliasing issues that force
// the compiler to generate extra loads from memory.

#include <cstdint>
#include <vector>
#include <stddef.h>

#include "aetypes.h"

// From https://travisdowns.github.io/blog/2019/08/26/vector-inc.html
void vector8_inc(std::vector<uint8_t> &v)
{
    for (size_t i = 0; i < v.size(); i++) {
        v[i]++;
    }
}

// Inspired by K2 src/isa/ebpf/inst_var.cc
// https://github.com/SeanHeelan/superopt/blob/407eb410466e1a21d081e96cc803ea6a59aa7e7e/src/isa/ebpf/inst_var.cc#L1251
void init_safety_chk(const std::vector<uint8_t> &reg_in, std::vector<uint8_t> &reg_out)
{
    for (int i = 0; i < reg_out.size(); ++i) {
        reg_out[i] = reg_in[i];
    }
}

// Inspired by K2 src/isa/ebpf/inst_var.cc
// https://github.com/SeanHeelan/superopt/blob/407eb410466e1a21d081e96cc803ea6a59aa7e7e/src/isa/ebpf/inst_var.cc#L1251
// Unlike init_safety_chk the in/out vectors are not passed by reference.
// However, due to how std::vector is implemented operator[] and the size
// function still require a dereference through the reg_in/reg_out variables in
// order to access required data.
void init_safety_chk_no_pointers(const std::vector<uint8_t> reg_in, std::vector<uint8_t> reg_out)
{
    for (int i = 0; i < reg_out.size(); ++i) {
        reg_out[i] = reg_in[i];
    }
}

// The inner loop of this function has a write that forces the compiler to
// generate code to reload the row pointers
void write2d_alias(char **buf, size_t x, size_t y)
{
    for (size_t i = 0; i < y; ++i) {
        for (size_t j = 0; j < x; ++j) {
            buf[i][j] = 0;
        }
    }
}

// The inner loop of this function has a write through a pointer to an int. There is 
// also a write through a char pointer meaning that the pointer to the int must be 
// loaded on each iteration.
void write_through_struct(char *buf, PointerHolder *ptr, int y, size_t cnt)
{
    *(ptr->x) = 0;
    for (size_t i = 0; i < cnt; ++i) {
        buf[i] = 'A';
        *(ptr->x) += i;
    }
}
