#include <mc_ruler.h>
#include <pmmintrin.h>

float dot(__m128 const& a, __m128 const& b)
{
    // Double check that cxx17 flag persists
    if constexpr (true)
    {
        MC_MEASURE_BEGIN(dot);
        float out;
        __m128 c = _mm_mul_ps(a, b);
        c        = _mm_hadd_ps(c, c);
        _mm_store_ss(&out, _mm_hadd_ps(c, c));
        return out;
        MC_MEASURE_END();
    }
}

float faster_dot(__m128 const& a, __m128 const& b)
{
    MC_MEASURE_BEGIN(faster_dot);
    __m128 s    = _mm_shuffle_ps(a, a, _MM_SHUFFLE(2, 3, 0, 1));
    __m128 sums = _mm_add_ps(a, s);
    s           = _mm_movehl_ps(s, sums);
    sums        = _mm_add_ss(sums, s);
    return _mm_cvtss_f32(sums);
    MC_MEASURE_END();
}

int bar(int a, int b)
{
    MC_MEASURE_BEGIN(bar);
    return a + b;
    MC_MEASURE_END();
}
