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

#ifndef _INTERVAL_H_
#define _INTERVAL_H_

#ifdef __cplusplus
#include <cstddef>

using std::size_t;

extern "C" {
#else
#include <stddef.h>
#endif

#include <EXTERN.h>
#include <perl.h>
  
/* User-defined item handling */
typedef SV *(*dup_f) ( SV *p );
typedef void  (*rel_f) ( SV *p );

typedef struct interval {

  float  low, high; /* Interval boundaries, inclusive */
  SV   *data;     /* User-defined content */
  dup_f  dup;       /* Clone an interval data item */
  rel_f  rel;       /* Destroy an interval data item */

} interval_t;
  
/* Interval functions */
interval_t *interval_new ( float, float, SV*, dup_f, rel_f );
interval_t *interval_copy(const interval_t*);
void       interval_delete ( interval_t* );
int        interval_overlap ( const interval_t*, const interval_t* );
/*
 * WARNING
 *
 * Comparison of floating-point values does not guarantee the correct results
 * and is subject to machine-dependent behaviour.
 *
 * This is critical and needs to be revised.
 */
int        interval_equal ( const interval_t*, const interval_t* );
		   
#ifdef __cplusplus
}
#endif

#endif /* _INTERVAL_H_ */
