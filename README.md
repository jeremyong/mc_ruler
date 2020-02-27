# MC Ruler

🎶 Drop the cycles, yo 🎶

MC Ruler (Machine Code Ruler) allows you to easily instrument your code and mark
segments to be analyzed with
[llvm-mca](https://llvm.org/docs/CommandGuide/llvm-mca.html). The tool then produces,
for each region marked to be analyzed, a separate report containing analysis
produced by llvm-mca.

## Quick Start

In your CMake file, add the following snippet to fetch this project as a
dependency into your build tree:

```cmake
include(FetchContent)
FetchContent_Declare(
    mc_ruler
    GIT_REPOSITORY https://github.com/jeremyong/mc_ruler.git
    GIT_TAG origin/master
)
FetchContent_MakeAvailable(mc_ruler)

include(MCRuler)
```

Then, for each target with code you want to instrument, do the following:

```cmake
# mc_ruler is an interface exposing a single header. No code is linked
# and the only thing that will change is the include path
target_link_libraries(my_target PUBLIC mc_ruler)
```

Finally, for each source file containing code you wish to instrument with llvm-mca,
do the following:

```c++
// In your C or C++ file (this example is dot_product.cpp)
// This header is included by the mc_ruler interface target
#include <mc_ruler.h>
#include <pmmintrin.h>

float dot_product(__m128 const& a, __m128 const& b)
{
    // Code you want to instrument should be surrounded with
    // MC_MEASURE_BEGIN and MC_MEAUSRE_END like so. Supply a name
    // for the region.
    MC_MEASURE_BEGIN(dot_product);
    __m128 s    = _mm_shuffle_ps(a, a, _MM_SHUFFLE(2, 3, 0, 1));
    __m128 sums = _mm_add_ps(a, s);
    s           = _mm_movehl_ps(s, sums);
    sums        = _mm_add_ss(sums, s);
    return _mm_cvtss_f32(sums);
    MC_MEASURE_END();
}
```

Then, in CMake, after your target is defined, do the following:

```cmake
mc_measure(
    my_target
    SOURCES
    dot_product.cpp
    # Any number of source files can be listed here
    LLVM_MCA_FLAGS # optional
    # Additional flags you wish to pass to llvm-mca
    # are optionally defined here
)
```

After building, there will be a new file in your project's binary tree,
in this case under `mc_ruler/my_target` with a file called `dot_product.mcr`.
The `.mcr` file is just a text file containing the output of the llvm-mca
analysis. In this case, the file emitted will have contents like this:

```
[0] Code Region - dot_product

Iterations:        100
Instructions:      4500
Total Cycles:      3204
Total uOps:        6600

Dispatch Width:    6
uOps Per Cycle:    2.06
IPC:               1.40
Block RThroughput: 15.0


Instruction Info:
[1]: #uOps
[2]: Latency
[3]: RThroughput
[4]: MayLoad
[5]: MayStore
[6]: HasSideEffects (U)

[1]    [2]    [3]    [4]    [5]    [6]    Instructions:
 1      5     0.50    *                   movq	-120(%rbp), %rax
 1      6     0.50    *                   movaps	(%rax), %xmm0
 1      1     1.00                        shufps	$177, %xmm0, %xmm0
 2      1     1.00           *            movaps	%xmm0, -144(%rbp)
 1      5     0.50    *                   movq	-120(%rbp), %rax
 1      6     0.50    *                   movaps	(%rax), %xmm0
 1      6     0.50    *                   movaps	-144(%rbp), %xmm1
 2      1     1.00           *            movaps	%xmm0, -96(%rbp)
 2      1     1.00           *            movaps	%xmm1, -112(%rbp)
 1      6     0.50    *                   movaps	-96(%rbp), %xmm0
 1      6     0.50    *                   movaps	-112(%rbp), %xmm1
 1      4     0.50                        addps	%xmm1, %xmm0
 2      1     1.00           *            movaps	%xmm0, -160(%rbp)
 1      6     0.50    *                   movaps	-144(%rbp), %xmm0
 1      6     0.50    *                   movaps	-160(%rbp), %xmm1
 2      1     1.00           *            movaps	%xmm0, -16(%rbp)
 2      1     1.00           *            movaps	%xmm1, -32(%rbp)
 1      6     0.50    *                   movapd	-16(%rbp), %xmm0
 1      6     0.50    *                   movapd	-32(%rbp), %xmm1
 1      1     1.00                        unpckhpd	%xmm0, %xmm1
 2      1     1.00           *            movapd	%xmm1, -144(%rbp)
 1      6     0.50    *                   movaps	-160(%rbp), %xmm0
 1      6     0.50    *                   movaps	-144(%rbp), %xmm1
 2      1     1.00           *            movaps	%xmm0, -48(%rbp)
 2      1     1.00           *            movaps	%xmm1, -64(%rbp)
 1      5     0.50    *                   movss	-64(%rbp), %xmm0
 1      6     0.50    *                   movaps	-48(%rbp), %xmm1
 1      4     0.50                        addss	%xmm0, %xmm1
 2      1     1.00           *            movaps	%xmm1, -48(%rbp)
 1      6     0.50    *                   movaps	-48(%rbp), %xmm0
 2      1     1.00           *            movaps	%xmm0, -160(%rbp)
 1      6     0.50    *                   movaps	-160(%rbp), %xmm0
 2      1     1.00           *            movaps	%xmm0, -80(%rbp)
 1      5     0.50    *                   movss	-80(%rbp), %xmm0
 1      1     0.25                        addq	$32, %rsp
 2      6     0.50    *                   popq	%rbp
 3      7     1.00                  U     retq
 3      2     1.00           *            pushq	%rbp
 1      1     0.25                        movq	%rsp, %rbp
 1      1     1.00           *            movl	%edi, -4(%rbp)
 1      1     1.00           *            movl	%esi, -8(%rbp)
 1      5     0.50    *                   movl	-4(%rbp), %eax
 2      6     0.50    *                   addl	-8(%rbp), %eax
 2      6     0.50    *                   popq	%rbp
 3      7     1.00                  U     retq


Resources:
[0]   - SKLDivider
[1]   - SKLFPDivider
[2]   - SKLPort0
[3]   - SKLPort1
[4]   - SKLPort2
[5]   - SKLPort3
[6]   - SKLPort4
[7]   - SKLPort5
[8]   - SKLPort6
[9]   - SKLPort7


Resource pressure per iteration:
[0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]
 -      -     3.49   3.49   15.99  16.00  15.00  3.51   3.51   7.01

Resource pressure by instruction:
[0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    Instructions:
 -      -      -      -      -     1.00    -      -      -      -     movq	-120(%rbp), %rax
 -      -      -      -     0.01   0.99    -      -      -      -     movaps	(%rax), %xmm0
 -      -      -      -      -      -      -     1.00    -      -     shufps	$177, %xmm0, %xmm0
 -      -      -      -      -      -     1.00    -      -     1.00   movaps	%xmm0, -144(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movq	-120(%rbp), %rax
 -      -      -      -     0.99   0.01    -      -      -      -     movaps	(%rax), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movaps	-144(%rbp), %xmm1
 -      -      -      -      -      -     1.00    -      -     1.00   movaps	%xmm0, -96(%rbp)
 -      -      -      -      -     1.00   1.00    -      -      -     movaps	%xmm1, -112(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movaps	-96(%rbp), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movaps	-112(%rbp), %xmm1
 -      -     0.49   0.51    -      -      -      -      -      -     addps	%xmm1, %xmm0
 -      -      -      -     1.00    -     1.00    -      -      -     movaps	%xmm0, -160(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movaps	-144(%rbp), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movaps	-160(%rbp), %xmm1
 -      -      -      -      -      -     1.00    -      -     1.00   movaps	%xmm0, -16(%rbp)
 -      -      -      -     0.98   0.02   1.00    -      -      -     movaps	%xmm1, -32(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movapd	-16(%rbp), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movapd	-32(%rbp), %xmm1
 -      -      -      -      -      -      -     1.00    -      -     unpckhpd	%xmm0, %xmm1
 -      -      -      -     0.02    -     1.00    -      -     0.98   movapd	%xmm1, -144(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movaps	-160(%rbp), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movaps	-144(%rbp), %xmm1
 -      -      -      -      -     0.98   1.00    -      -     0.02   movaps	%xmm0, -48(%rbp)
 -      -      -      -     0.98   0.02   1.00    -      -      -     movaps	%xmm1, -64(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movss	-64(%rbp), %xmm0
 -      -      -      -      -     1.00    -      -      -      -     movaps	-48(%rbp), %xmm1
 -      -     0.51   0.49    -      -      -      -      -      -     addss	%xmm0, %xmm1
 -      -      -      -     0.01    -     1.00    -      -     0.99   movaps	%xmm1, -48(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movaps	-48(%rbp), %xmm0
 -      -      -      -      -     0.99   1.00    -      -     0.01   movaps	%xmm0, -160(%rbp)
 -      -      -      -      -     1.00    -      -      -      -     movaps	-160(%rbp), %xmm0
 -      -      -      -     0.99   0.01   1.00    -      -      -     movaps	%xmm0, -80(%rbp)
 -      -      -      -     1.00    -      -      -      -      -     movss	-80(%rbp), %xmm0
 -      -      -     0.49    -      -      -     0.01   0.50    -     addq	$32, %rsp
 -      -     0.01    -      -     1.00    -     0.50   0.49    -     popq	%rbp
 -      -     0.49   0.50   1.00    -      -     0.01   1.00    -     retq
 -      -     0.49   0.49   0.01    -     1.00   0.01   0.01   0.99   pushq	%rbp
 -      -     0.01   0.50    -      -      -      -     0.49    -     movq	%rsp, %rbp
 -      -      -      -     0.98    -     1.00    -      -     0.02   movl	%edi, -4(%rbp)
 -      -      -      -      -      -     1.00    -      -     1.00   movl	%esi, -8(%rbp)
 -      -      -      -      -     1.00    -      -      -      -     movl	-4(%rbp), %eax
 -      -     0.49    -     1.00    -      -     0.49   0.02    -     addl	-8(%rbp), %eax
 -      -     0.50   0.01   0.02   0.98    -     0.49    -      -     popq	%rbp
 -      -     0.50   0.50    -     1.00    -      -     1.00    -     retq
```

## How does it work?

Internally, MC Ruler defines a new target for every source file passed to the
`mc_measure` CMake function. All the properties from the original target are copied
to the new target so that it compiles properly with the correct compile definitions,
library linkages, include directories, etc. Then, it is compiled as an individual target
with additional flags set to ensure the assembly is saved.
Finally, `llvm-mca` is invoked on the generated assembly to emit the analysis file
as shown above.

It is recommended to only enable mc_ruler when the CMake build type is `RELEASE` as
there is not much use in analyzing unoptimized code.

Other details worth noting are that if you have source files in a nested directory,
the emitted `mcr` analysis files will be stored with a similar nesting with the
target's folder (which will itself be within `${PROJECT_BINARY_DIR}/mc_ruler`).

The `test` directory in this repo contains an example mini-project which builds
when this project is compiled as a standalone.

## Footnote

This project has the unfortunate property of possessing the lamest project name
I have ever come up with.
