/* matrix/view_source.c
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001 Gerard Jungman, Brian Gough
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

QUALIFIED_VIEW(_gsl_matrix, view)
    FUNCTION(gsl_matrix, view_array) (QUALIFIER ATOMIC * array,
				  const size_t n1, const size_t n2)
{
    QUALIFIED_VIEW(_gsl_matrix, view) view = NULL_MATRIX_VIEW;

    if (n1 == 0) {
	GSL_ERROR_VAL("matrix dimension n1 must be positive integer",
		      GSL_EINVAL, view);
    } else if (n2 == 0) {
	GSL_ERROR_VAL("matrix dimension n2 must be positive integer",
		      GSL_EINVAL, view);
    }

    {
	TYPE(gsl_matrix) m = NULL_MATRIX;

	m.data = (ATOMIC *) array;
	m.size1 = n1;
	m.size2 = n2;
	m.tda = n2;
	m.block = 0;
	m.owner = 0;

	view.matrix = m;
	return view;
    }
}

QUALIFIED_VIEW(_gsl_matrix, view)
    FUNCTION(gsl_matrix, view_array_with_tda) (QUALIFIER ATOMIC * base,
					   const size_t n1,
					   const size_t n2,
					   const size_t tda)
{
    QUALIFIED_VIEW(_gsl_matrix, view) view = NULL_MATRIX_VIEW;

    if (n1 == 0) {
	GSL_ERROR_VAL("matrix dimension n1 must be positive integer",
		      GSL_EINVAL, view);
    } else if (n2 == 0) {
	GSL_ERROR_VAL("matrix dimension n2 must be positive integer",
		      GSL_EINVAL, view);
    } else if (n2 > tda) {
	GSL_ERROR_VAL("matrix dimension n2 must not exceed tda",
		      GSL_EINVAL, view);
    }


    {
	TYPE(gsl_matrix) m = NULL_MATRIX;

	m.data = (ATOMIC *) base;
	m.size1 = n1;
	m.size2 = n2;
	m.tda = tda;
	m.block = 0;
	m.owner = 0;

	view.matrix = m;
	return view;
    }
}

QUALIFIED_VIEW(_gsl_matrix, view)
    FUNCTION(gsl_matrix, view_vector) (QUALIFIED_TYPE(gsl_vector) * v,
				   const size_t n1, const size_t n2)
{
    QUALIFIED_VIEW(_gsl_matrix, view) view = NULL_MATRIX_VIEW;

    if (n1 == 0) {
	GSL_ERROR_VAL("matrix dimension n1 must be positive integer",
		      GSL_EINVAL, view);
    } else if (n2 == 0) {
	GSL_ERROR_VAL("matrix dimension n2 must be positive integer",
		      GSL_EINVAL, view);
    } else if (v->stride != 1) {
	GSL_ERROR_VAL("vector must have unit stride", GSL_EINVAL, view);
    } else if (n1 * n2 > v->size) {
	GSL_ERROR_VAL("matrix size exceeds size of original",
		      GSL_EINVAL, view);
    }

    {
	TYPE(gsl_matrix) m = NULL_MATRIX;

	m.data = v->data;
	m.size1 = n1;
	m.size2 = n2;
	m.tda = n2;
	m.block = v->block;
	m.owner = 0;

	view.matrix = m;
	return view;
    }
}


QUALIFIED_VIEW(_gsl_matrix, view)
    FUNCTION(gsl_matrix, view_vector_with_tda) (QUALIFIED_TYPE(gsl_vector) * v,
					    const size_t n1,
					    const size_t n2,
					    const size_t tda)
{
    QUALIFIED_VIEW(_gsl_matrix, view) view = NULL_MATRIX_VIEW;

    if (n1 == 0) {
	GSL_ERROR_VAL("matrix dimension n1 must be positive integer",
		      GSL_EINVAL, view);
    } else if (n2 == 0) {
	GSL_ERROR_VAL("matrix dimension n2 must be positive integer",
		      GSL_EINVAL, view);
    } else if (v->stride != 1) {
	GSL_ERROR_VAL("vector must have unit stride", GSL_EINVAL, view);
    } else if (n2 > tda) {
	GSL_ERROR_VAL("matrix dimension n2 must not exceed tda",
		      GSL_EINVAL, view);
    } else if (n1 * tda > v->size) {
	GSL_ERROR_VAL("matrix size exceeds size of original",
		      GSL_EINVAL, view);
    }

    {
	TYPE(gsl_matrix) m = NULL_MATRIX;

	m.data = v->data;
	m.size1 = n1;
	m.size2 = n2;
	m.tda = tda;
	m.block = v->block;
	m.owner = 0;

	view.matrix = m;
	return view;
    }
}


