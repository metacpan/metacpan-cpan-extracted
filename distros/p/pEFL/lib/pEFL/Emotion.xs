#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Emotion.h>

#include "const-emotion-c.inc"

MODULE = pEFL::Emotion		PACKAGE = pEFL::Emotion     PREFIX = emotion_

INCLUDE: const-ecore-xs.inc

Eina_Bool
emotion_init()

Eina_Bool
emotion_shutdown()