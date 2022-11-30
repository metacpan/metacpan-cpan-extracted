#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef struct PerlStringSet 
{
	int count;
	char *str[1];
} PerlStringSet;

typedef Edje_Message_String_Set EdjeMessageStringSet;

MODULE = pEFL::Edje::Message::StringSet		PACKAGE = pEFL::Edje::Message::StringSet

EdjeMessageStringSet *
_new(class,count, val_arr)
	char *class
	int count
	AV *val_arr
PREINIT:
	EdjeMessageStringSet *message;
	int index;
	SV *tmp;
	char *string;
	STRLEN len;
CODE:
	Newx(message,1,EdjeMessageStringSet);
	Renewc(message,count+2, char*,EdjeMessageStringSet);
	if (message == NULL) 
		croak("Failed to allocate memory in _new function\n");
	message->count = count+1;
	for (index = 0; index <= count; index++) {
		tmp = *av_fetch(val_arr,index,0);
		string = SvPVutf8(tmp,len);
		message->str[index] = savepvn(string,len);
	}
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::StringSet		PACKAGE = EdjeMessageStringSetPtr

int
count(message)
    EdjeMessageStringSet *message
CODE:
    RETVAL = message->count;
OUTPUT:
    RETVAL
    
void
str(message)
    EdjeMessageStringSet *message
PREINIT:
	int count;
	char **vals;
	int index;
PPCODE:
    count = message->count;
    vals = message->str;
    
    EXTEND(SP,count);
    for (index = 0; index <count; index ++) {
    	PUSHs( sv_2mortal( newSVpv( vals[index], 0 ) ));
	}
	
void
DESTROY(message) 
    EdjeMessageStringSet *message
PREINIT:
	int count;
	char **vals;
	int index;
CODE:
	Safefree(message);
	//printf("Freeing Message_String_Set\n");