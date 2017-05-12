/* blas/blas.c
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001 Gerard Jungman & Brian 
 * Gough
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

/* GSL implementation of BLAS operations for vectors and dense
 * matrices.  Note that GSL native storage is row-major.  */


#include "gsl_math.h"
#include "gsl_errno.h"
#include "gsl_cblas.h"
#include "gsl_blas_types.h"
#include "gsl_blas.h"
#include "../mprintf.h"

#define OFFSET(N, incX) ((incX) > 0 ?  0 : ((N) - 1) * (-(incX)))

static double
cblas_ddot(const int N, const double *X, const int incX, const double *Y,
	   const int incY)

/* blas/source_dot_r.h
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000 Gerard Jungman
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

{
    double r = 0.0;
    int i;
    int ix = OFFSET(N, incX);
    int iy = OFFSET(N, incY);

    for (i = 0; i < N; i++) {
	r += X[ix] * Y[iy];
	ix += incX;
	iy += incY;
    }

    return r;
}


/* ========================================================================
 * Level 1
 * ========================================================================
 */

/* CBLAS defines vector sizes in terms of int. GSL defines sizes in
   terms of size_t, so we need to convert these into integers.  There
   is the possibility of overflow here. FIXME: Maybe this could be
   caught */

#define INT(X) ((int)(X))


int
gsl_blas_ddot(const gsl_vector * X, const gsl_vector * Y, double *result)
{
    if (X->size == Y->size) {
	*result =
	    cblas_ddot(INT(X->size), X->data, INT(X->stride), Y->data,
		       INT(Y->stride));
	return GSL_SUCCESS;
    } else {
	GSL_ERROR("invalid length", GSL_EBADLEN);
    }
}

static void
cblas_dgemv(const enum CBLAS_ORDER order,
	    const enum CBLAS_TRANSPOSE TransA, const int M, const int N,
	    const double alpha, const double *A, const int lda,
	    const double *X, const int incX, const double beta, double *Y,
	    const int incY)
/* blas/source_gemv_r.h
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000 Gerard Jungman
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

{
    int i, j;
    int lenX, lenY;
    const char *this_sub = "cblas_dgemv";
    const int Trans = (TransA != CblasConjTrans) ? TransA : CblasTrans;

    if (M == 0 || N == 0)
	return;

    if (alpha == 0.0 && beta == 1.0)
	return;

    if (Trans == CblasNoTrans) {
	lenX = N;
	lenY = M;
    } else {
	lenX = M;
	lenY = N;
    }

    /* form  y := beta*y */
    if (beta == 0.0) {
	int iy = OFFSET(lenY, incY);
	for (i = 0; i < lenY; i++) {
	    Y[iy] = 0.0;
	    iy += incY;
	}
    } else if (beta != 1.0) {
	int iy = OFFSET(lenY, incY);
	for (i = 0; i < lenY; i++) {
	    Y[iy] *= beta;
	    iy += incY;
	}
    }

    if (alpha == 0.0)
	return;

    if ((order == CblasRowMajor && Trans == CblasNoTrans)
	|| (order == CblasColMajor && Trans == CblasTrans)) {
	/* form  y := alpha*A*x + y */
	int iy = OFFSET(lenY, incY);
	for (i = 0; i < lenY; i++) {
	    double temp = 0.0;
	    int ix = OFFSET(lenX, incX);
	    for (j = 0; j < lenX; j++) {
		temp += X[ix] * A[lda * i + j];
		ix += incX;
	    }
	    Y[iy] += alpha * temp;
	    iy += incY;
	}
    } else if ((order == CblasRowMajor && Trans == CblasTrans)
	       || (order == CblasColMajor && Trans == CblasNoTrans)) {
	/* form  y := alpha*A'*x + y */
	int ix = OFFSET(lenX, incX);
	for (j = 0; j < lenX; j++) {
	    const double temp = alpha * X[ix];
	    if (temp != 0.0) {
		int iy = OFFSET(lenY, incY);
		for (i = 0; i < lenY; i++) {
		    Y[iy] += temp * A[lda * j + i];
		    iy += incY;
		}
	    }
	    ix += incX;
	}
    } else {
	err_printf(this_sub, "unrecognized operation");
    }
}



/* ===========================================================================
 * Level 2
 * ===========================================================================
 */


/* GEMV */

int
gsl_blas_dgemv(CBLAS_TRANSPOSE_t TransA, double alpha,
	       const gsl_matrix * A, const gsl_vector * X, double beta,
	       gsl_vector * Y)
{
    const size_t M = A->size1;
    const size_t N = A->size2;

    if ((TransA == CblasNoTrans && N == X->size && M == Y->size)
	|| (TransA == CblasTrans && M == X->size && N == Y->size)) {
	cblas_dgemv(CblasRowMajor, TransA, INT(M), INT(N), alpha, A->data,
		    INT(A->tda), X->data, INT(X->stride), beta, Y->data,
		    INT(Y->stride));
	return GSL_SUCCESS;
    } else {
	GSL_ERROR("invalid length", GSL_EBADLEN);
    }
}
