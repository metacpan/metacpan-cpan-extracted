#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = WWW::Shopify::Liquid::XS		PACKAGE = WWW::Shopify::Liquid::XS		

SV* 
minify_internal(inputString, length)
	const char* inputString
	long length
	CODE:
		char* outBuffer = malloc(length+1);
		long outputLength = minify(my_perl, inputString, outBuffer);
		SV* value = newSVpvn(outBuffer, outputLength-1);
		free(outBuffer);
		RETVAL = value;
	OUTPUT:
		RETVAL