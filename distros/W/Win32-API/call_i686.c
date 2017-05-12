#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <memory.h>

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "API.h"
#define IS_CALL_I686_C
/* no compiler check since that is done in Makefile.PL */
#include "call_i686.h"
