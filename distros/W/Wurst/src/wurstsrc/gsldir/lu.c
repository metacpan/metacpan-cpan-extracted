/* linalg/lu.c
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

/* Author:  G. Jungman */

#include <stdlib.h>
#include <string.h>
#include "gsl_math.h"
#include "gsl_vector_double.h"
#include "gsl_matrix_double.h"
#include "gsl_blas.h"

#include "gsl_linalg.h"

#include "../mprintf.h"

#define OFFSET(N, incX) ((incX) > 0 ?  0 : ((N) - 1) * (-(incX)))

#define REAL double

static void gsl_permutation_init(gsl_permutation * p)
{
    const size_t n = p->size;
    size_t i;

    /* initialize permutation to identity */

    for (i = 0; i < n; i++) {
	p->data[i] = i;
    }
}

static int
gsl_permutation_swap(gsl_permutation * p, const size_t i, const size_t j)
{
    const size_t size = p->size;

    if (i >= size) {
	GSL_ERROR("first index is out of range", GSL_EINVAL);
    }

    if (j >= size) {
	GSL_ERROR("second index is out of range", GSL_EINVAL);
    }

    if (i != j) {
	size_t tmp = p->data[i];
	p->data[i] = p->data[j];
	p->data[j] = tmp;
    }

    return GSL_SUCCESS;
}


/* Factorise a general N x N matrix A into,
 *
 *   P A = L U
 *
 * where P is a permutation matrix, L is unit lower triangular and U
 * is upper triangular.
 *
 * L is stored in the strict lower triangular part of the input
 * matrix. The diagonal elements of L are unity and are not stored.
 *
 * U is stored in the diagonal and upper triangular part of the
 * input matrix.  
 * 
 * P is stored in the permutation p. Column j of P is column k of the
 * identity matrix, where k = permutation->data[j]
 *
 * signum gives the sign of the permutation, (-1)^n, where n is the
 * number of interchanges in the permutation. 
 *
 * See Golub & Van Loan, Matrix Computations, Algorithm 3.4.1 (Gauss
 * Elimination with Partial Pivoting).
 */

int gsl_linalg_LU_decomp(gsl_matrix * A, gsl_permutation * p, int *signum)
{
    if (A->size1 != A->size2) {
	GSL_ERROR("LU decomposition requires square matrix", GSL_ENOTSQR);
    } else if (p->size != A->size1) {
	GSL_ERROR("permutation length must match matrix size",
		  GSL_EBADLEN);
    } else {
	const size_t N = A->size1;
	size_t i, j, k;

	*signum = 1;
	gsl_permutation_init(p);

	for (j = 0; j < N - 1; j++) {
	    /* Find maximum in the j-th column */

	    REAL ajj, max = fabs(gsl_matrix_get(A, j, j));
	    size_t i_pivot = j;

	    for (i = j + 1; i < N; i++) {
		REAL aij = fabs(gsl_matrix_get(A, i, j));

		if (aij > max) {
		    max = aij;
		    i_pivot = i;
		}
	    }

	    if (i_pivot != j) {
		gsl_matrix_swap_rows(A, j, i_pivot);
		gsl_permutation_swap(p, j, i_pivot);
		*signum = -(*signum);
	    }

	    ajj = gsl_matrix_get(A, j, j);

	    if (ajj != 0.0) {
		for (i = j + 1; i < N; i++) {
		    REAL aij = gsl_matrix_get(A, i, j) / ajj;
		    gsl_matrix_set(A, i, j, aij);

		    for (k = j + 1; k < N; k++) {
			REAL aik = gsl_matrix_get(A, i, k);
			REAL ajk = gsl_matrix_get(A, j, k);
			gsl_matrix_set(A, i, k, aik - aij * ajk);
		    }
		}
	    }
	}

	return GSL_SUCCESS;
    }
}

static void
cblas_dtrsv(const enum CBLAS_ORDER order, const enum CBLAS_UPLO Uplo,
	    const enum CBLAS_TRANSPOSE TransA, const enum CBLAS_DIAG Diag,
	    const int N, const double *A, const int lda, double *X,
	    const int incX)
/* blas/source_trsv_r.h
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
    const int nonunit = (Diag == CblasNonUnit);
    int ix, jx;
    int i, j;
    const char *this_sub = "cblas_dtrsv";
    const int Trans = (TransA != CblasConjTrans) ? TransA : CblasTrans;

    if (N == 0)
	return;

    /* form  x := inv( A )*x */

    if ((order == CblasRowMajor && Trans == CblasNoTrans
	 && Uplo == CblasUpper)
	|| (order == CblasColMajor && Trans == CblasTrans
	    && Uplo == CblasLower)) {
	/* backsubstitution */
	ix = OFFSET(N, incX) + incX * (N - 1);
	if (nonunit) {
	    X[ix] = X[ix] / A[lda * (N - 1) + (N - 1)];
	}
	ix -= incX;
	for (i = N - 1; i > 0 && i--;) {
	    double tmp = X[ix];
	    jx = ix + incX;
	    for (j = i + 1; j < N; j++) {
		const double Aij = A[lda * i + j];
		tmp -= Aij * X[jx];
		jx += incX;
	    }
	    if (nonunit) {
		X[ix] = tmp / A[lda * i + i];
	    } else {
		X[ix] = tmp;
	    }
	    ix -= incX;
	}
    } else
	if ((order == CblasRowMajor && Trans == CblasNoTrans
	     && Uplo == CblasLower)
	    || (order == CblasColMajor && Trans == CblasTrans
		&& Uplo == CblasUpper)) {

	/* forward substitution */
	ix = OFFSET(N, incX);
	if (nonunit) {
	    X[ix] = X[ix] / A[lda * 0 + 0];
	}
	ix += incX;
	for (i = 1; i < N; i++) {
	    double tmp = X[ix];
	    jx = OFFSET(N, incX);
	    for (j = 0; j < i; j++) {
		const double Aij = A[lda * i + j];
		tmp -= Aij * X[jx];
		jx += incX;
	    }
	    if (nonunit) {
		X[ix] = tmp / A[lda * i + i];
	    } else {
		X[ix] = tmp;
	    }
	    ix += incX;
	}
    } else
	if ((order == CblasRowMajor && Trans == CblasTrans
	     && Uplo == CblasUpper)
	    || (order == CblasColMajor && Trans == CblasNoTrans
		&& Uplo == CblasLower)) {

	/* form  x := inv( A' )*x */

	/* forward substitution */
	ix = OFFSET(N, incX);
	if (nonunit) {
	    X[ix] = X[ix] / A[lda * 0 + 0];
	}
	ix += incX;
	for (i = 1; i < N; i++) {
	    double tmp = X[ix];
	    jx = OFFSET(N, incX);
	    for (j = 0; j < i; j++) {
		const double Aji = A[lda * j + i];
		tmp -= Aji * X[jx];
		jx += incX;
	    }
	    if (nonunit) {
		X[ix] = tmp / A[lda * i + i];
	    } else {
		X[ix] = tmp;
	    }
	    ix += incX;
	}
    } else
	if ((order == CblasRowMajor && Trans == CblasTrans
	     && Uplo == CblasLower)
	    || (order == CblasColMajor && Trans == CblasNoTrans
		&& Uplo == CblasUpper)) {

	/* backsubstitution */
	ix = OFFSET(N, incX) + (N - 1) * incX;
	if (nonunit) {
	    X[ix] = X[ix] / A[lda * (N - 1) + (N - 1)];
	}
	ix -= incX;
	for (i = N - 1; i > 0 && i--;) {
	    double tmp = X[ix];
	    jx = ix + incX;
	    for (j = i + 1; j < N; j++) {
		const double Aji = A[lda * j + i];
		tmp -= Aji * X[jx];
		jx += incX;
	    }
	    if (nonunit) {
		X[ix] = tmp / A[lda * i + i];
	    } else {
		X[ix] = tmp;
	    }
	    ix -= incX;
	}
    } else {
	err_printf(this_sub, "unrecognized operation");
    }

}


static int
gsl_blas_dtrsv(CBLAS_UPLO_t Uplo, CBLAS_TRANSPOSE_t TransA,
	       CBLAS_DIAG_t Diag, const gsl_matrix * A, gsl_vector * X)
{
    const size_t M = A->size1;
    const size_t N = A->size2;

    if (M != N) {
	GSL_ERROR("matrix must be square", GSL_ENOTSQR);
    } else if (N != X->size) {
	GSL_ERROR("invalid length", GSL_EBADLEN);
    }

    cblas_dtrsv(CblasRowMajor, Uplo, TransA, Diag, (int) N, A->data,
		(int) (A->tda), X->data, (int) (X->stride));
    return GSL_SUCCESS;
}
#define BASE_DOUBLE
#include "templates_on.h"
static int
TYPE(gsl_permute) (const size_t * p, ATOMIC * data, const size_t stride,
		   const size_t n) {
    size_t i, k, pk;

    for (i = 0; i < n; i++) {
	k = p[i];

	while (k > i)
	    k = p[k];

	if (k < i)
	    continue;

	/* Now have k == i, i.e the least in its cycle */

	pk = p[k];

	if (pk == i)
	    continue;

	/* shuffle the elements of the cycle */

	{
	    unsigned int a;

	    ATOMIC t[MULTIPLICITY];

	    for (a = 0; a < MULTIPLICITY; a++)
		t[a] = data[i * stride * MULTIPLICITY + a];

	    while (pk != i) {
		for (a = 0; a < MULTIPLICITY; a++) {
		    ATOMIC r1 = data[pk * stride * MULTIPLICITY + a];
		    data[k * stride * MULTIPLICITY + a] = r1;
		}
		k = pk;
		pk = p[k];
	    };

	    for (a = 0; a < MULTIPLICITY; a++)
		data[k * stride * MULTIPLICITY + a] = t[a];
	}
    }

    return GSL_SUCCESS;
}


static int
TYPE(gsl_permute_vector) (const gsl_permutation * p, TYPE(gsl_vector) * v)
{
    if (v->size != p->size) {
	GSL_ERROR("vector and permutation must be the same length",
		  GSL_EBADLEN);
    }

    TYPE(gsl_permute) (p->data, v->data, v->stride, v->size);

    return GSL_SUCCESS;
}
#include "templates_off.h"
#undef BASE_DOUBLE

int
gsl_linalg_LU_svx(const gsl_matrix * LU, const gsl_permutation * p,
		  gsl_vector * x)
{
    if (LU->size1 != LU->size2) {
	GSL_ERROR("LU matrix must be square", GSL_ENOTSQR);
    } else if (LU->size1 != p->size) {
	GSL_ERROR("permutation length must match matrix size",
		  GSL_EBADLEN);
    } else if (LU->size1 != x->size) {
	GSL_ERROR("matrix size must match solution/rhs size", GSL_EBADLEN);
    } else {
	/* Apply permutation to RHS */

	gsl_permute_vector(p, x);

	/* Solve for c using forward-substitution, L c = P b */

	gsl_blas_dtrsv(CblasLower, CblasNoTrans, CblasUnit, LU, x);

	/* Perform back-substitution, U x = c */

	gsl_blas_dtrsv(CblasUpper, CblasNoTrans, CblasNonUnit, LU, x);

	return GSL_SUCCESS;
    }
}

int
gsl_linalg_LU_invert(const gsl_matrix * LU, const gsl_permutation * p,
		     gsl_matrix * inverse)
{
    size_t i, n = LU->size1;

    int status = GSL_SUCCESS;

    gsl_matrix_set_identity(inverse);

    for (i = 0; i < n; i++) {
	gsl_vector_view c = gsl_matrix_column(inverse, i);
	int status_i = gsl_linalg_LU_svx(LU, p, &(c.vector));

	if (status_i)
	    status = status_i;
    }

    return status;
}

double gsl_linalg_LU_det(gsl_matrix * LU, int signum)
{
    size_t i, n = LU->size1;

    double det = (double) signum;

    for (i = 0; i < n; i++) {
	det *= gsl_matrix_get(LU, i, i);
    }

    return det;
}
