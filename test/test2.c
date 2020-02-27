#include <mc_ruler.h>

int foo(int a, int b)
{
    MC_MEASURE_BEGIN(foo);
    return a + b;
    MC_MEASURE_END();
}