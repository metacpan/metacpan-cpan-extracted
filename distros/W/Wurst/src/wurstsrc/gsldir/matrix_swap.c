#include "gsl_matrix_double.h"
#include "gsl_vector_double.h"
#include "gsl_errno.h"

#define BASE_DOUBLE
#include "templates_on.h"
#include "matrix_swap_source.c"
#include "templates_off.h"
#undef  BASE_DOUBLE
