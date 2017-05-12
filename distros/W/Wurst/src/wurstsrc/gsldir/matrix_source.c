/* matrix/matrix_source.c
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

#ifndef HIDE_INLINE_STATIC
BASE
FUNCTION(gsl_matrix, get) (const TYPE(gsl_matrix) * m,
			   const size_t i, const size_t j) {
    return *(BASE *) (m->data + MULTIPLICITY * (i * m->tda + j));
}

void
FUNCTION(gsl_matrix, set) (TYPE(gsl_matrix) * m,
			   const size_t i, const size_t j, const BASE x) {
    *(BASE *) (m->data + MULTIPLICITY * (i * m->tda + j)) = x;
}
#endif
