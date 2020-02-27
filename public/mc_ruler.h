#pragma once

// llvm-mca is only supported with Clang
#ifdef __clang__

// This enabling macro is set as a compile flag automatically when the CMake
// function `mc_ruler` is called on a target and the including source file is
// specified.
#    ifdef MC_RULER_ENABLED
#        define MC_MEASURE_BEGIN(name) __asm volatile("# LLVM-MCA-BEGIN " #        name)
#        define MC_MEASURE_END() __asm volatile("# LLVM-MCA-END")
#    else
#        define MC_MEASURE_BEGIN(name)
#        define MC_MEASURE_END()
#    endif

#endif