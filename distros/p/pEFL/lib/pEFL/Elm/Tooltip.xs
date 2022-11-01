#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Tooltip		PACKAGE = pEFL::Elm::Tooltip


MODULE = pEFL::Elm::Tooltip		PACKAGE = ElmTooltipPtr     PREFIX = elm_tooltip_


