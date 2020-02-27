#include <mc_ruler.h>

int foo(int a, int b)
{
    MC_MEASURE_BEGIN(foo);
    int out = a + b;
    MC_MEASURE_END();
    return out;
}