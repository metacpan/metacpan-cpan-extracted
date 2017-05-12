/* block/init_source.c
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000 Gerard Jungman, Brian Gough
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
#include "../e_malloc.h"

TYPE(gsl_block) * FUNCTION(gsl_block, alloc) (const size_t n)
{
    TYPE(gsl_block) * b;

    if (n == 0) {
	GSL_ERROR_VAL("block length n must be positive integer",
		      GSL_EINVAL, 0);
    }

    b = (TYPE(gsl_block) *) E_MALLOC(sizeof(TYPE(gsl_block)));

    b->data = (ATOMIC *) E_MALLOC(MULTIPLICITY * n * sizeof(ATOMIC));

    if (b->data == 0) {
	free(b);		/* exception in constructor, avoid memory leak */
    }

    b->size = n;

    return b;
}


void FUNCTION(gsl_block, free) (TYPE(gsl_block) * b) {
    free(b->data);
    free(b);
}
