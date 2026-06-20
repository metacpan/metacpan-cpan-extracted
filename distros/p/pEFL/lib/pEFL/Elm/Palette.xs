#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

typedef Elm_Palette ElmPalette;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Palette		PACKAGE = pEFL::Elm::Palette



MODULE = pEFL::Elm::Palette		PACKAGE = ElmPalettePtr

int
version(pal)
    ElmPalette *pal
CODE:
    RETVAL = pal->version;
OUTPUT:
    RETVAL
    
    
EinaList *
colors(pal)
	ElmPalette *pal
CODE:
    RETVAL = pal->colors;
OUTPUT:
    RETVAL