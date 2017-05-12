/*
 * 16 nov 2005
 * This is a source of random numbers. For the moment, only
 * gaussian distributed ones. In the spirit of keeping wurst code
 * small, we only include the functions we want, which are
 * floating point numbers. Should we want more, there is some
 * code in my .../gene/srand.c file which will return all
 * different types like integers, short integers and so on.
 * The routines use the underlying posix xrand48() functions.
 *
 * $Id: rand.c,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */

#include <math.h>
#include <stdlib.h>

#include "rand.h"

const long int DEFAULT_SEED = 64067;
/* ---------------- ini_rand  ---------------------------------
 */
void
ini_rand( long int seed )
{
    srand48 (seed);
}

#ifdef want_size_t
/* ---------------- st_r_rand ---------------------------------
 * Return a random number of type size_t, within the specified
 * range.
 */
size_t
st_r_rand (size_t min, size_t max)
{
    long unsigned int lu = (long unsigned int) mrand48();
    size_t u = (size_t) lu; /* possible truncation here */
    return (u%(max - min + 1) + min);
}
#endif /* want_size_t */

/* ---------------- hidden_g_rand -----------------------------
 * Return a gaussian distributed random number. Mean is zero,
 * variance is 1.
 * This is the Box_Mueller transformed version. It generates two
 * random numbers. So we store the second, whenever we generate
 * it. On alternate calls, just return the stored one.
 */
static float
hidden_g_rand (void)
{
    float w, x1, x2;
    static float oldx;
    static char have_x = 0;
    if (have_x) {                  /* Just change the flag */
        have_x = 0;                /* and return the stored value */
        return oldx;
    }
    do {
        x1 = 2 * drand48() - 1.0;
        x2 = 2 * drand48() - 1.0;
        w = x1 * x1 + x2 * x2;        /* Are numbers in unit circle ? */
    } while ( w >= 1.0 || w == 0.0);
    w = sqrt( (-2.0 * log( w ) ) / w );
    oldx = x1 * w;             /* Save this for next time. */
    have_x = 1;                /* Flag used in the test above */
    return (x2 * w);
}

/* ---------------- g_rand  -----------------------------------
 * Return gaussian distributed random number with specified mean
 * and standard deviation.
 */
float
g_rand (const float mean, const float std_dev)
{
    float tmp = hidden_g_rand();
    tmp *= std_dev;
    tmp += mean;
    return (tmp);
}

#ifdef want_st_g_rand

/* ---------------- st_g_rand ---------------------------------
 * g_rand() gives us a floating point. This is to return items
 * of type size_t. If our mean is outside the range, return 0 and
 * hope the caller is clever enough to notice we are upset.
 */
size_t
st_g_rand (size_t mean, size_t std_dev)
{
    float x;
    size_t r;
    if (mean >= SSIZE_MAX)
        return 0;

    x = SSIZE_MAX + 1.0;
    do { 
        x = g_rand (mean, std_dev);
        r = (size_t) rint (x);
    } while ( x >= SSIZE_MAX);
    return r;
}
#endif /* want_st_g_rand */

#undef TESTME
#ifdef TESTME
#include <stdio.h>
int main ()
{
    long long unsigned int i;
    long long unsigned int max = 0;
    long long int min = -1;
    for (i = 0; i < 999999; i++) {
        unsigned int j = s_r_rand (0, 32000);
        if (j < min)
            min = j;
        if (j > max)
            max = j;
    }
    printf ("At end min %lld max %llu\n", min, max);
    for (i = 0; i < 100; i++)
        printf ("%u   ", s_r_rand (3, 70));
    return (EXIT_SUCCESS);
}
#endif /* TESTME */
