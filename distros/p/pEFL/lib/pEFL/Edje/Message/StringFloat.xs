#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_String_Float EdjeMessageStringFloat;

MODULE = pEFL::Edje::Message::StringFloat		PACKAGE = pEFL::Edje::Message::StringFloat

EdjeMessageStringFloat *
new(class,string,val)
	char *class
	char *string
	double val
PREINIT:
	EdjeMessageStringFloat *message;
CODE:
	if (items != 3) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::StringFloat->new($string, $val)\n");
	}
	message->str = string;
	message->val = val;
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::StringFloat		PACKAGE = EdjeMessageStringFloatPtr

char*
str(message)
    EdjeMessageStringFloat *message
CODE:
    RETVAL = message->str;
OUTPUT:
    RETVAL
    

double
val(message)
    EdjeMessageStringFloat *message
CODE:
    RETVAL = message->val;
OUTPUT:
    RETVAL