#include <mc_ruler.h>
#include <string>

std::string foo(std::string const& a, std::string const& b)
{
    MC_MEASURE_BEGIN(foo);
    std::string out = a + b;
    MC_MEASURE_END();
    return out;
}