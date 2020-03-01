#pragma once

// specified.
#ifdef MC_RULER_ENABLED
// llvm-mca is only supported with Clang and GCC
#    if defined(__clang__) || defined(__GNUC__)

// This enabling macro is set as a compile flag automatically when the CMake
// function `mc_ruler` is called on a target and the including source file is
#        define MC_MEASURE_BEGIN(name) __asm volatile("# LLVM-MCA-BEGIN " #        name)
#        define MC_MEASURE_END() __asm volatile("# LLVM-MCA-END")
#    else
#        define MC_MEASURE_BEGIN(name)
#        define MC_MEASURE_END()
#    endif

#else
#    define MC_MEASURE_BEGIN(name)
#    define MC_MEASURE_END()
#endif