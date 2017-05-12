/* blas/gsl_blas.h
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

/*
 * Author:  G. Jungman
 */
#ifndef __GSL_BLAS_H__
#define __GSL_BLAS_H__

#include "gsl_vector_double.h"
#include "gsl_matrix_double.h"

#include "gsl_blas_types.h"


#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS		/* empty */
# define __END_DECLS		/* empty */
#endif

__BEGIN_DECLS
/* ========================================================================
 * Level 1
 * ========================================================================
 */
int gsl_blas_ddot(const gsl_vector * X,
		  const gsl_vector * Y, double *result);



/* ===========================================================================
 * Level 2
 * ===========================================================================
 */

/*
 * Routines with standard 4 prefixes (S, D, C, Z)
 */

int gsl_blas_dgemv(CBLAS_TRANSPOSE_t TransA,
		   double alpha,
		   const gsl_matrix * A,
		   const gsl_vector * X, double beta, gsl_vector * Y);





/*
 * ===========================================================================
 * Prototypes for level 3 BLAS
 * ===========================================================================
 */


int gsl_blas_dgemm(CBLAS_TRANSPOSE_t TransA,
		   CBLAS_TRANSPOSE_t TransB,
		   double alpha,
		   const gsl_matrix * A,
		   const gsl_matrix * B, double beta, gsl_matrix * C);


__END_DECLS
#endif				/* __GSL_BLAS_H__ */
