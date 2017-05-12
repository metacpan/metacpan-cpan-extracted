/* matrix/swap_source.c
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

int
FUNCTION(gsl_matrix, swap_rows) (TYPE(gsl_matrix) * m,
				 const size_t i, const size_t j) {
    const size_t size1 = m->size1;
    const size_t size2 = m->size2;

    if (i >= size1) {
	GSL_ERROR("first row index is out of range", GSL_EINVAL);
    }

    if (j >= size1) {
	GSL_ERROR("second row index is out of range", GSL_EINVAL);
    }

    if (i != j) {
	ATOMIC *row1 = m->data + MULTIPLICITY * i * m->tda;
	ATOMIC *row2 = m->data + MULTIPLICITY * j * m->tda;

	size_t k;

	for (k = 0; k < MULTIPLICITY * size2; k++) {
	    ATOMIC tmp = row1[k];
	    row1[k] = row2[k];
	    row2[k] = tmp;
	}
    }

    return GSL_SUCCESS;
}
