#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include "canon/canon.h"
#include <libxml/globals.h>
#include "const-c.inc"

MODULE = XML::CanonicalizeXML		PACKAGE = XML::CanonicalizeXML		

INCLUDE: const-xs.inc

SV *  
canonicalize (xml,xpath,namespace,exclusive,with_comments)
		char*     xml
		char*     xpath
		char *    namespace
		int exclusive
		int with_comments
	    PREINIT:
               xmlChar *output               = NULL;	  
	       int error = 0;  
	    CODE:
	        xmlInitParser();
                error = canonicalize(xml,xpath,namespace,exclusive,with_comments,&output);	
		if (error < 0 ) {
		    croak("Failed to conanonicalize string");
		} else {    
		  RETVAL = newSVpvn( (const char *)output, xmlStrlen(output) ); 
                  xmlFree(output);
		}  
		xmlCleanupParser();
	    OUTPUT:
		RETVAL  
