/*
 * Libitree: an interval tree library in C 
 *
 * Copyright (C) 2018 Alessandro Vullo 
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/

#ifndef _UTILS_H_
#define _UTILS_H_

#ifdef __cplusplus
#include <cmath>
#include <cfloat>
#include <cstdbool>

using std::size_t;

extern "C" {
#else
#include <math.h>
#include <float.h>
#include <stdbool.h>
#endif

#define BIGRND 0x7fffffff

typedef unsigned int uint;

/* Generate a random number between 0.0 and 1.0 */
double rnd01() {
  return ((double) random() / (double) BIGRND);
}

/* Generate a random number between -1.0 and +1.0 */
double nrnd01() {
  return ((rnd01() * 2.0) - 1.0);
}

/*
 * From http://floating-point-gui.de, Michael Borgwardt
 *
 * A presumably good method for comparing floating-point values using precision.
 *
 */
/* bool nearly_equal(float a, float b, float epsilon) { */
/*   float abs_a = fabs ( a ); */
/*   float abs_b = fabs ( b ); */
/*   float diff  = fabs ( a - b ); */

/*   if ( a == b ) // shortcut, handles infinities *\/ */
/*     return true; */
/*   else if ( a == 0 || b == 0 ||  ( abs_a + abs_b < FLT_MIN ) )  */
/*     /\* a or b is zero or both are extremely close to it */
/*        relative error is less meaningful here *\/ */
/*     return diff < ( epsilon * FLT_MIN ); */
/*   else /\* use relative error *\/ */
/*     return diff / fmin( (abs_a + abs_b), FLT_MAX ) < epsilon; */
/* } */

#endif /* _UTILS_H_ */
