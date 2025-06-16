#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmConformant;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Conformant		PACKAGE = pEFL::Elm::Conformant

ElmConformant *
elm_conformant_add(EvasObject *parent)
