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

#include "interval.h"

#ifdef __cplusplus
#include <cstdlib>

using std::malloc;
using std::free;
using std::size_t;
#else
#include <stdlib.h>
#include <stdio.h>
#endif

interval_t *interval_new ( float low, float high, SV *data, dup_f dup, rel_f rel ) {
  interval_t *ri = (interval_t*) malloc ( sizeof *ri );

  if ( ri == NULL )
    return NULL;

  ri->low = low;
  ri->high = high;
  ri->dup = dup;
  ri->rel = rel;
  ri->data = ri->dup( data );

  return ri;
}

interval_t *interval_copy ( const interval_t *i ) {
  return interval_new ( i->low, i->high, i->data, i->dup, i->rel );
}

void interval_delete ( interval_t *i ) {
  if ( i != NULL ) {
    if ( i->data ) i->rel ( i->data );
    free ( i );
  }

}

int interval_overlap(const interval_t* i1, const interval_t* i2) {
  return i1->low <= i2->high && i2->low <= i1->high;
}

/*
 * WARNING
 *
 * Comparison of floating-point values does not guarantee the correct results
 * and is subject to machine-dependent behaviour.
 *
 * This is critical and needs to be revised.
 */
int interval_equal(const interval_t* i1, const interval_t* i2) {
  return i1->low == i2->low && i1->high == i2->high;
}
