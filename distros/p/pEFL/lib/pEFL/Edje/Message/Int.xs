#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_Int EdjeMessageInt;

MODULE = pEFL::Edje::Message::Int		PACKAGE = pEFL::Edje::Message::Int

EdjeMessageInt *
new(class,val)
	char *class
	int val
PREINIT:
	EdjeMessageInt *message;
CODE:
	if (items != 2) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::Int->new($val)\n");
	}
	message->val = val;
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::Int		PACKAGE = EdjeMessageIntPtr

int
int(message)
    EdjeMessageInt *message
CODE:
    RETVAL = message->val;
OUTPUT:
    RETVAL