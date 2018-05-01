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

#ifndef _INTERVAL_TREE_H_
#define _INTERVAL_TREE_H_

/*
  Interval Tree library

  This is an adaptation of the AVL balanced tree C library
  created by Julienne Walker which can be found here:

  http://www.eternallyconfuzzled.com/Libraries.aspx

*/
#ifdef __cplusplus
#include <cstddef>

using std::size_t;

extern "C" {
#else
#include <stddef.h>
#endif

#include "interval.h"
#include "interval_list.h"
  
/* Opaque types */
typedef struct itree itree_t;
typedef struct itreetrav itreetrav_t;

/* Interval tree functions */
itree_t    *itree_new ( dup_f dup, rel_f rel );
void       itree_delete ( itree_t *tree );
interval_t *itree_find ( itree_t *tree, interval_t *interval );
ilist_t    *itree_findall ( itree_t *tree, interval_t *interval );
int        itree_insert ( itree_t *tree, interval_t *interval );
int        itree_remove ( itree_t *tree, interval_t *interval );
size_t     itree_size ( itree_t *tree );

/* Tree traversal functions */
itreetrav_t *itreetnew ( void );
void        itreetdelete ( itreetrav_t *trav );
interval_t  *itreetfirst ( itreetrav_t *trav, itree_t *tree );
interval_t  *itreetlast ( itreetrav_t *trav, itree_t *tree );
interval_t  *itreetnext ( itreetrav_t *trav );
interval_t  *itreetprev ( itreetrav_t *trav );

#ifdef __cplusplus
}
#endif

#endif /* _INTERVAL_TREE_H_ */
