/* linalg/gsl_linalg.h
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

#ifndef __GSL_LINALG_H__
#define __GSL_LINALG_H__

#include "gsl_mode.h"
#include "gsl_permutation.h"
#include "gsl_vector_double.h"
#include "gsl_matrix_double.h"

#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
#define __BEGIN_DECLS extern "C" {
#define __END_DECLS }
#else
#define __BEGIN_DECLS		/* empty */
#define __END_DECLS		/* empty */
#endif

__BEGIN_DECLS typedef enum {
    GSL_LINALG_MOD_NONE = 0,
    GSL_LINALG_MOD_TRANSPOSE = 1,
    GSL_LINALG_MOD_CONJUGATE = 2
} gsl_linalg_matrix_mod_t;


/* Note: You can now use the gsl_blas_dgemm function instead of matmult */

/* Simple implementation of matrix multiply.
 * Calculates C = A.B
 *
 * exceptions: GSL_EBADLEN
 */
int gsl_linalg_matmult(const gsl_matrix * A,
		       const gsl_matrix * B, gsl_matrix * C);


/* Simple implementation of matrix multiply.
 * Allows transposition of either matrix, so it
 * can compute A.B or Trans(A).B or A.Trans(B) or Trans(A).Trans(B)
 *
 * exceptions: GSL_EBADLEN
 */
int gsl_linalg_matmult_mod(const gsl_matrix * A,
			   gsl_linalg_matrix_mod_t modA,
			   const gsl_matrix * B,
			   gsl_linalg_matrix_mod_t modB, gsl_matrix * C);

/* Calculate the matrix exponential by the scaling and
 * squaring method described in Moler + Van Loan,
 * SIAM Rev 20, 801 (1978). The mode argument allows
 * choosing an optimal strategy, from the table
 * given in the paper, for a given precision.
 *
 * exceptions: GSL_ENOTSQR, GSL_EBADLEN
 */
int gsl_linalg_exponential_ss(const gsl_matrix * A,
			      gsl_matrix * eA, gsl_mode_t mode);


/* Householder Transformations */

double gsl_linalg_householder_transform(gsl_vector * v);


int gsl_linalg_householder_hm(double tau,
			      const gsl_vector * v, gsl_matrix * A);

int gsl_linalg_householder_mh(double tau,
			      const gsl_vector * v, gsl_matrix * A);

int gsl_linalg_householder_hv(double tau,
			      const gsl_vector * v, gsl_vector * w);

int gsl_linalg_householder_hm1(double tau, gsl_matrix * A);

/* Singular Value Decomposition

 * exceptions: 
 */

int
gsl_linalg_SV_decomp(gsl_matrix * A,
		     gsl_matrix * V, gsl_vector * S, gsl_vector * work);

int
gsl_linalg_SV_decomp_mod(gsl_matrix * A,
			 gsl_matrix * X,
			 gsl_matrix * V,
			 gsl_vector * S, gsl_vector * work);

int gsl_linalg_SV_decomp_jacobi(gsl_matrix * A,
				gsl_matrix * Q, gsl_vector * S);

int
gsl_linalg_SV_solve(const gsl_matrix * U,
		    const gsl_matrix * Q,
		    const gsl_vector * S,
		    const gsl_vector * b, gsl_vector * x);


/* LU Decomposition, Gaussian elimination with partial pivoting
 */

int gsl_linalg_LU_decomp(gsl_matrix * A, gsl_permutation * p, int *signum);

int gsl_linalg_LU_solve(const gsl_matrix * LU,
			const gsl_permutation * p,
			const gsl_vector * b, gsl_vector * x);

int gsl_linalg_LU_svx(const gsl_matrix * LU,
		      const gsl_permutation * p, gsl_vector * x);

int gsl_linalg_LU_refine(const gsl_matrix * A,
			 const gsl_matrix * LU,
			 const gsl_permutation * p,
			 const gsl_vector * b,
			 gsl_vector * x, gsl_vector * residual);

int gsl_linalg_LU_invert(const gsl_matrix * LU,
			 const gsl_permutation * p, gsl_matrix * inverse);

double gsl_linalg_LU_det(gsl_matrix * LU, int signum);
double gsl_linalg_LU_lndet(gsl_matrix * LU);
int gsl_linalg_LU_sgndet(gsl_matrix * lu, int signum);


/* QR decomposition */

int gsl_linalg_QR_decomp(gsl_matrix * A, gsl_vector * tau);

int gsl_linalg_QR_solve(const gsl_matrix * QR,
			const gsl_vector * tau,
			const gsl_vector * b, gsl_vector * x);

int gsl_linalg_QR_svx(const gsl_matrix * QR,
		      const gsl_vector * tau, gsl_vector * x);

int gsl_linalg_QR_lssolve(const gsl_matrix * QR,
			  const gsl_vector * tau,
			  const gsl_vector * b,
			  gsl_vector * x, gsl_vector * residual);


int gsl_linalg_QR_QRsolve(gsl_matrix * Q,
			  gsl_matrix * R,
			  const gsl_vector * b, gsl_vector * x);

int gsl_linalg_QR_Rsolve(const gsl_matrix * QR,
			 const gsl_vector * b, gsl_vector * x);

int gsl_linalg_QR_Rsvx(const gsl_matrix * QR, gsl_vector * x);

int gsl_linalg_QR_update(gsl_matrix * Q,
			 gsl_matrix * R,
			 gsl_vector * w, const gsl_vector * v);

int gsl_linalg_QR_QTvec(const gsl_matrix * QR,
			const gsl_vector * tau, gsl_vector * v);

int gsl_linalg_QR_Qvec(const gsl_matrix * QR,
		       const gsl_vector * tau, gsl_vector * v);

int gsl_linalg_QR_unpack(const gsl_matrix * QR,
			 const gsl_vector * tau,
			 gsl_matrix * Q, gsl_matrix * R);

int gsl_linalg_R_solve(const gsl_matrix * R,
		       const gsl_vector * b, gsl_vector * x);

int gsl_linalg_R_svx(const gsl_matrix * R, gsl_vector * x);


/* Q R P^T decomposition */

int gsl_linalg_QRPT_decomp(gsl_matrix * A,
			   gsl_vector * tau,
			   gsl_permutation * p,
			   int *signum, gsl_vector * norm);

int gsl_linalg_QRPT_decomp2(const gsl_matrix * A,
			    gsl_matrix * q, gsl_matrix * r,
			    gsl_vector * tau,
			    gsl_permutation * p,
			    int *signum, gsl_vector * norm);

int gsl_linalg_QRPT_solve(const gsl_matrix * QR,
			  const gsl_vector * tau,
			  const gsl_permutation * p,
			  const gsl_vector * b, gsl_vector * x);


int gsl_linalg_QRPT_svx(const gsl_matrix * QR,
			const gsl_vector * tau,
			const gsl_permutation * p, gsl_vector * x);

int gsl_linalg_QRPT_QRsolve(const gsl_matrix * Q,
			    const gsl_matrix * R,
			    const gsl_permutation * p,
			    const gsl_vector * b, gsl_vector * x);

int gsl_linalg_QRPT_Rsolve(const gsl_matrix * QR,
			   const gsl_permutation * p,
			   const gsl_vector * b, gsl_vector * x);

int gsl_linalg_QRPT_Rsvx(const gsl_matrix * QR,
			 const gsl_permutation * p, gsl_vector * x);

int gsl_linalg_QRPT_update(gsl_matrix * Q,
			   gsl_matrix * R,
			   const gsl_permutation * p,
			   gsl_vector * u, const gsl_vector * v);

/* LQ decomposition */

int gsl_linalg_LQ_decomp(gsl_matrix * A, gsl_vector * tau);

int gsl_linalg_LQ_solve_T(const gsl_matrix * LQ, const gsl_vector * tau,
			  const gsl_vector * b, gsl_vector * x);

int gsl_linalg_LQ_svx_T(const gsl_matrix * LQ, const gsl_vector * tau,
			gsl_vector * x);

int gsl_linalg_LQ_lssolve_T(const gsl_matrix * LQ, const gsl_vector * tau,
			    const gsl_vector * b, gsl_vector * x,
			    gsl_vector * residual);

int gsl_linalg_LQ_Lsolve_T(const gsl_matrix * LQ, const gsl_vector * b,
			   gsl_vector * x);

int gsl_linalg_LQ_Lsvx_T(const gsl_matrix * LQ, gsl_vector * x);

int gsl_linalg_L_solve_T(const gsl_matrix * L, const gsl_vector * b,
			 gsl_vector * x);

int gsl_linalg_LQ_vecQ(const gsl_matrix * LQ, const gsl_vector * tau,
		       gsl_vector * v);

int gsl_linalg_LQ_vecQT(const gsl_matrix * LQ, const gsl_vector * tau,
			gsl_vector * v);

int gsl_linalg_LQ_unpack(const gsl_matrix * LQ, const gsl_vector * tau,
			 gsl_matrix * Q, gsl_matrix * L);

int gsl_linalg_LQ_update(gsl_matrix * Q, gsl_matrix * R,
			 const gsl_vector * v, gsl_vector * w);
int gsl_linalg_LQ_LQsolve(gsl_matrix * Q, gsl_matrix * L,
			  const gsl_vector * b, gsl_vector * x);

/* P^T L Q decomposition */

int gsl_linalg_PTLQ_decomp(gsl_matrix * A, gsl_vector * tau,
			   gsl_permutation * p, int *signum,
			   gsl_vector * norm);

int gsl_linalg_PTLQ_decomp2(const gsl_matrix * A, gsl_matrix * q,
			    gsl_matrix * r, gsl_vector * tau,
			    gsl_permutation * p, int *signum,
			    gsl_vector * norm);

int gsl_linalg_PTLQ_solve_T(const gsl_matrix * QR,
			    const gsl_vector * tau,
			    const gsl_permutation * p,
			    const gsl_vector * b, gsl_vector * x);

int gsl_linalg_PTLQ_svx_T(const gsl_matrix * LQ,
			  const gsl_vector * tau,
			  const gsl_permutation * p, gsl_vector * x);

int gsl_linalg_PTLQ_LQsolve_T(const gsl_matrix * Q, const gsl_matrix * L,
			      const gsl_permutation * p,
			      const gsl_vector * b, gsl_vector * x);

int gsl_linalg_PTLQ_Lsolve_T(const gsl_matrix * LQ,
			     const gsl_permutation * p,
			     const gsl_vector * b, gsl_vector * x);

int gsl_linalg_PTLQ_Lsvx_T(const gsl_matrix * LQ,
			   const gsl_permutation * p, gsl_vector * x);

int gsl_linalg_PTLQ_update(gsl_matrix * Q, gsl_matrix * L,
			   const gsl_permutation * p,
			   const gsl_vector * v, gsl_vector * w);

/* Cholesky Decomposition */

int gsl_linalg_cholesky_decomp(gsl_matrix * A);

int gsl_linalg_cholesky_solve(const gsl_matrix * cholesky,
			      const gsl_vector * b, gsl_vector * x);

int gsl_linalg_cholesky_svx(const gsl_matrix * cholesky, gsl_vector * x);

/* Symmetric to symmetric tridiagonal decomposition */

int gsl_linalg_symmtd_decomp(gsl_matrix * A, gsl_vector * tau);

int gsl_linalg_symmtd_unpack(const gsl_matrix * A,
			     const gsl_vector * tau,
			     gsl_matrix * Q,
			     gsl_vector * diag, gsl_vector * subdiag);

int gsl_linalg_symmtd_unpack_T(const gsl_matrix * A,
			       gsl_vector * diag, gsl_vector * subdiag);


/* Linear Solve Using Householder Transformations
 * exceptions: 
 */

int gsl_linalg_HH_solve(gsl_matrix * A, const gsl_vector * b,
			gsl_vector * x);
int gsl_linalg_HH_svx(gsl_matrix * A, gsl_vector * x);

/* Linear solve for a symmetric tridiagonal system.

 * The input vectors represent the NxN matrix as follows:
 *
 *     diag[0]  offdiag[0]             0    ...
 *  offdiag[0]     diag[1]    offdiag[1]    ...
 *           0  offdiag[1]       diag[2]    ...
 *           0           0    offdiag[2]    ...
 *         ...         ...           ...    ...
 */
int gsl_linalg_solve_symm_tridiag(const gsl_vector * diag,
				  const gsl_vector * offdiag,
				  const gsl_vector * b, gsl_vector * x);

/* Linear solve for a nonsymmetric tridiagonal system.

 * The input vectors represent the NxN matrix as follows:
 *
 *       diag[0]  abovediag[0]              0    ...
 *  belowdiag[0]       diag[1]   abovediag[1]    ...
 *             0  belowdiag[1]        diag[2]    ...
 *             0             0   belowdiag[2]    ...
 *           ...           ...            ...    ...
 */
int gsl_linalg_solve_tridiag(const gsl_vector * diag,
			     const gsl_vector * abovediag,
			     const gsl_vector * belowdiag,
			     const gsl_vector * b, gsl_vector * x);


/* Linear solve for a symmetric cyclic tridiagonal system.

 * The input vectors represent the NxN matrix as follows:
 *
 *      diag[0]  offdiag[0]             0   .....  offdiag[N-1]
 *   offdiag[0]     diag[1]    offdiag[1]   .....
 *            0  offdiag[1]       diag[2]   .....
 *            0           0    offdiag[2]   .....
 *          ...         ...
 * offdiag[N-1]         ...
 */
int gsl_linalg_solve_symm_cyc_tridiag(const gsl_vector * diag,
				      const gsl_vector * offdiag,
				      const gsl_vector * b,
				      gsl_vector * x);

/* Linear solve for a nonsymmetric cyclic tridiagonal system.

 * The input vectors represent the NxN matrix as follows:
 *
 *        diag[0]  abovediag[0]             0   .....  belowdiag[N-1]
 *   belowdiag[0]       diag[1]  abovediag[1]   .....
 *              0  belowdiag[1]       diag[2]
 *              0             0  belowdiag[2]   .....
 *            ...           ...
 * abovediag[N-1]           ...
 */
int gsl_linalg_solve_cyc_tridiag(const gsl_vector * diag,
				 const gsl_vector * abovediag,
				 const gsl_vector * belowdiag,
				 const gsl_vector * b, gsl_vector * x);


/* Bidiagonal decomposition */

int gsl_linalg_bidiag_decomp(gsl_matrix * A,
			     gsl_vector * tau_U, gsl_vector * tau_V);

int gsl_linalg_bidiag_unpack(const gsl_matrix * A,
			     const gsl_vector * tau_U,
			     gsl_matrix * U,
			     const gsl_vector * tau_V,
			     gsl_matrix * V,
			     gsl_vector * diag, gsl_vector * superdiag);

int gsl_linalg_bidiag_unpack2(gsl_matrix * A,
			      gsl_vector * tau_U,
			      gsl_vector * tau_V, gsl_matrix * V);

int gsl_linalg_bidiag_unpack_B(const gsl_matrix * A,
			       gsl_vector * diag, gsl_vector * superdiag);

/* Balancing */

int gsl_linalg_balance_columns(gsl_matrix * A, gsl_vector * D);


__END_DECLS
#endif				/* __GSL_LINALG_H__ */
