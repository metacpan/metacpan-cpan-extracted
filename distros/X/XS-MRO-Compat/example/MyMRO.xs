#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "mro_compat.h"

typedef HV STASH;

MODULE = MyMRO		PACKAGE = MyMRO

PROTOTYPES: DISABLE

AV*
mro_get_linear_isa(STASH* package)

U32
mro_get_pkg_gen(STASH* package)

U32
mro_get_cache_gen(STASH* package)

U32
mro_get_gen(STASH* package)

void
mro_method_changed_in(STASH* package)

