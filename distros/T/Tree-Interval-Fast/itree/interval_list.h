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

#ifndef _INTERVAL_LIST_H_
#define _INTERVAL_LIST_H_

#ifdef __cplusplus
#include <cstddef>

using std::size_t;

extern "C" {
#else
#include <stddef.h>
#endif

#include "interval.h"

/* Declarations for an interval list, opaque types */
typedef struct ilist ilist_t;
typedef struct ilisttrav ilisttrav_t;

/* Interval list functions */
ilist_t     *ilist_new ();
void        ilist_delete ( ilist_t* );
size_t      ilist_size ( ilist_t* );
int         ilist_append ( ilist_t*, interval_t* );

/* Interval list traversal functions */
ilisttrav_t *ilisttrav_new ( ilist_t* );
void        ilisttrav_delete ( ilisttrav_t *trav );
const interval_t  *ilisttrav_first ( ilisttrav_t *trav );
const interval_t  *ilisttrav_last ( ilisttrav_t *trav );
const interval_t  *ilisttrav_next ( ilisttrav_t *trav );
const interval_t  *ilisttrav_prev ( ilisttrav_t *trav );

#ifdef __cplusplus
}
#endif

#endif /* _INTERVAL_LIST_H_ */
