#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_String EdjeMessageString;

MODULE = pEFL::Edje::Message::String		PACKAGE = pEFL::Edje::Message::String

EdjeMessageString *
new(class,str)
	char *class
	SV *str
PREINIT:
	EdjeMessageString *message;
	char *string;
	STRLEN len;
CODE:
	if (items != 2) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::String->new($string)\n");
	}
	New(0,message,1,EdjeMessageString);
	string = SvPV(str,len);
	message->str = savepvn(string,len);
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::String		PACKAGE = EdjeMessageStringPtr

char*
str(message)
    EdjeMessageString *message
CODE:
    RETVAL = message->str;
OUTPUT:
    RETVAL
    
    
void
DESTROY(message) 
    EdjeMessageString *message
CODE:
	//printf("Freeing Message_String\n");
	Safefree(message);