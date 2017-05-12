#include "gsl_math.h"
#include "gsl_matrix_double.h"
#include "gsl_vector_double.h"
#include "gsl_errno.h"

#include "matrix_view.h"

#define BASE_DOUBLE
#include "templates_on.h"
#include "matrix_rowcol_source.c"
#include "templates_off.h"
#undef  BASE_DOUBLE
