#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmPlayer;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Player		PACKAGE = pEFL::Elm::Player

ElmPlayer * 
elm_player_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Player		PACKAGE = ElmPlayerPtr     PREFIX = elm_bg_

