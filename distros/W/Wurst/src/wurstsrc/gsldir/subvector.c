#include <stdlib.h>
#include "gsl_vector_double.h"

#include "view.h"

#define BASE_DOUBLE
#include "templates_on.h"
#include "subvector_source.c"
#include "templates_off.h"
#undef  BASE_DOUBLE

#define USE_QUALIFIER
#define QUALIFIER const

#define BASE_DOUBLE
#include "templates_on.h"
#include "subvector_source.c"
#include "templates_off.h"
#undef  BASE_DOUBLE
