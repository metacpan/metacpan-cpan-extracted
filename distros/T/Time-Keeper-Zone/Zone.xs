#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "time_keeper_zone_abi.h"
#include "tkz/tkz_types.h"
#include "tkz/tkz_data.h"
#include "tkz/tkz_engine.h"
#include "tkz/tkz_local.h"
#include "tkz/tkz_abi_impl.h"
#include "tkz/tkz_dump.h"

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

PROTOTYPES: DISABLE

INCLUDE: xs/zone.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/data.xs
INCLUDE: xs/engine.xs
INCLUDE: xs/rules.xs
INCLUDE: xs/test.xs
