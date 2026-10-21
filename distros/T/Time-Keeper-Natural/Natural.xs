#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>

#include "time_keeper_abi.h"

#include "tkn/tkn_cxt.h"
#include "tkn/tkn_norm.h"
#include "tkn/tkn_lexicon.h"
#include "tkn/tkn_patterns.h"
#include "tkn/tkn_numbers.h"
#include "tkn/tkn_words.h"
#include "tkn/tkn_relative.h"
#include "tkn/tkn_duration.h"
#include "tkn/tkn_absolute.h"
#include "tkn/tkn_grammar.h"
#include "tkn/tkn_match.h"
#include "tkn/tkn_surface.h"
#include "tkn/tkn_interval.h"
#include "tkn/tkn_days.h"
#include "tkn/tkn_zones.h"
#include "tkn/tkn_fractions.h"
#include "tkn/tkn_points.h"
#include "tkn/tkn_find.h"

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    tkn_cxt_init(aTHX_ &MY_CXT);
    tkn_abi_resolve(aTHX);
}

INCLUDE: xs/natural.xs
INCLUDE: xs/lexicon.xs
INCLUDE: xs/numbers.xs
INCLUDE: xs/words.xs
INCLUDE: xs/relative.xs
INCLUDE: xs/duration.xs
INCLUDE: xs/absolute.xs
INCLUDE: xs/grammar.xs
INCLUDE: xs/match.xs
INCLUDE: xs/surface.xs
INCLUDE: xs/interval.xs
INCLUDE: xs/find.xs
