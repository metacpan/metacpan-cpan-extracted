#include "gsl_errno.h"
#include "gsl_vector_double.h"
#include "gsl_permute.h"
#include "gsl_permute_vector_double.h"

#define BASE_DOUBLE
#include "templates_on.h"
#include "permute_source.c"
#include "templates_off.h"
#undef  BASE_DOUBLE
