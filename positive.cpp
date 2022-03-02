// This file contains examples that have the sorts of aliasing issues that force
// the compiler to generate extra loads from memory.

#include <stddef.h>

#include <cstdint>
#include <vector>

#include "aetypes.h"

// From https://travisdowns.github.io/blog/2019/08/26/vector-inc.html
void vector8_inc(std::vector<uint8_t> &v) {
    for (size_t i = 0; i < v.size(); i++) {
        v[i]++;
    }
}

// As above, but char
void vector8_inc(std::vector<char> &v) {
    for (size_t i = 0; i < v.size(); i++) {
        v[i] = (char)((uint8_t)v[i] + 1);
    }
}

// Inspired by K2 src/isa/ebpf/inst_var.cc
// https://github.com/SeanHeelan/superopt/blob/407eb410466e1a21d081e96cc803ea6a59aa7e7e/src/isa/ebpf/inst_var.cc#L1251
void init_safety_chk(const std::vector<uint8_t> &reg_in, std::vector<uint8_t> &reg_out) {
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
void init_safety_chk_no_pointers(const std::vector<uint8_t> reg_in, std::vector<uint8_t> reg_out) {
    for (int i = 0; i < reg_out.size(); ++i) {
        reg_out[i] = reg_in[i];
    }
}

// The inner loop of this function has a write that forces the compiler to
// generate code to reload the row pointers
void write2d_alias(char **buf, size_t x, size_t y) {
    for (size_t i = 0; i < y; ++i) {
        for (size_t j = 0; j < x; ++j) {
            buf[i][j] = 0;
        }
    }
}

// The inner loop of this function has a write through a pointer to an int. There is
// also a write through a char pointer meaning that the pointer to the int must be
// loaded on each iteration.
void write_through_struct(char *buf, PointerHolder *ptr, int y, size_t cnt) {
    *(ptr->x) = 0;
    for (size_t i = 0; i < cnt; ++i) {
        buf[i] = 'A';
        *(ptr->x) += i;
    }
}

// The inner loop of this function has a write to an int inside a struct that is
// passed by pointer. This means the int must be loaded from memory on each
// iteration of the loop due to the write through the char type, as the location
// written to by the char type may overlap with the ptr->x int.
void write_to_int_in_mem(char *buf, ValHolder *ptr, int y, size_t cnt) {
    ptr->x = 0;
    for (size_t i = 0; i < cnt; ++i) {
        buf[i] = 'A';
        ptr->x += i;
    }
}

// Loop with alias of a character type that is accessed through a pointer that is
// in a struct.
void char_alias_through_struct(char *buf, PointerHolder *ptr, int y, size_t cnt) {
    *(ptr->x) = 0;
    for (size_t i = 0; i < cnt; ++i) {
        *(ptr->c) = 1;
        *(ptr->x) += i;
    }
}

// Demonstrates a case where the base pointer is unchanged on the second access
void base_ptr_unchanged(char *buf, ValHolder *v1, ValHolder *v2) {
    v1->x = 10;
    v2 = v1;
    buf[0] = 'A';
    // If it weren't for the char write the compiler could optimise this function
    // to a single write of 20. Instead it must emit an `add [&ptr->x], 10` here
    v1->x += 10;
}

// Base ptr is changed, but after the loop
void base_ptr_changed_later(char *buf, PointerHolder *ptr, int y, size_t cnt) {
    for (size_t i = 0; i < cnt; ++i) {
        // Write through char type
        *(ptr->c) = 1;
        // x must be loaded every time due to the char write
        *(ptr->x) += i;
   }

   ptr++;
   *(ptr->x) += cnt;
}

// Partner of add_vals_no_alias in negative.cpp
void add_vals(char *buf, float *out, int in[], size_t offset) {
    *out += in[offset];
    buf[0] = 'A';
    *out += in[offset];
}
