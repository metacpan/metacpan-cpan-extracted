#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_String_Int EdjeMessageStringInt;

MODULE = pEFL::Edje::Message::StringInt		PACKAGE = pEFL::Edje::Message::StringInt

EdjeMessageStringInt *
new(class,string,val)
	char *class
	char *string
	int val
PREINIT:
	EdjeMessageStringInt *message;
CODE:
	if (items != 3) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::Float->new($string, $val)\n");
	}
	message->str = string;
	message->val = val;
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::StringInt		PACKAGE = EdjeMessageStringIntPtr

char*
str(message)
    EdjeMessageStringInt *message
CODE:
    RETVAL = message->str;
OUTPUT:
    RETVAL