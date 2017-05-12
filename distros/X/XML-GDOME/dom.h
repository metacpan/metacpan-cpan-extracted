#ifndef __LIBXML_DOM_H__
#define __LIBXML_DOM_H__

xmlChar*
domEncodeString( const char *encoding, const char *string );
char*
domDecodeString( const char *encoding, const xmlChar *string);

#endif
