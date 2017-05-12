#ifndef _XML_FAST_H_
#define _XML_FAST_H_

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include "entities.h"

#ifndef safemalloc
#define safemalloc malloc
#endif
#ifndef safecalloc
#define safecalloc calloc
#endif
#ifndef safefree
#define safefree free
#endif
#ifndef saferealloc
#define saferealloc realloc
#endif
#ifndef Newx
#define Newx(v,n,t) (v = ( (t*)safemalloc((size_t)((n)*sizeof(t))) ) )
#endif
#ifndef Newxz
#define Newxz(v,n,t) (v = ( (t*)safecalloc((n),sizeof(t)) ) )
#endif
#ifndef Renew
#define Renew(v,n,t) (v = ( (t*)saferealloc((void *)(v),(size_t)((n)*sizeof(t))) ) )
#endif
#ifndef Safefree
#define Safefree(d) safefree((void *)(d))
#endif

#define PROCESSING_INSTRUCTION 0x0001
#define TEXT_NODE              0x0002

typedef struct {
	char * str;
	char * val;
} entity;

typedef struct {
	char *name;
	char *value;
} xml_attr;

typedef void (*xml_callback)(void *,char *, unsigned int, unsigned int);

typedef struct {
	void (*piopen)(void *,char *, unsigned int);
	void (*piclose)(void *,char *, unsigned int);
	void (*comment)(void *,char *, unsigned int);
	void (*cdata)(void *,char *, unsigned int);
	void (*tagopen)(void *,char *, unsigned int);
	void (*attrname)(void *,char *, unsigned int);
	void (*tagclose)(void *,char *, unsigned int);
	void (*bytespart)(void *, char *, unsigned int);
	void (*bytes)(void *, char *, unsigned int);
	void (*uchar)(void *, wchar_t);

	void (*warn)(void *, char *, ...);
	void (*die)(void *, char *, ...);
} xml_callbacks;

/*
typedef struct {
	char *name;
	unsigned int len;
} xml_node;
*/

typedef struct {
	unsigned        line_number;
	char          * last_newline;
	unsigned int    save_wsp;
	unsigned int    state;
	
/*	unsigned int    chain_size;
	xml_node      * root;
	xml_node      * chain;
	int             depth;
*/
	
	unsigned int    pathsize;
	unsigned int    pathlen;
	char          * path;
	
	xml_callbacks   cb;
	void          * ctx;          // context for the caller, black box for us
} parser_state;

// BUFFER used for some dummy copy operations. May be safely reduced to smaller numbers
#define BUFFER 4096
#define xml_error(x) do { \
	if (context->cb.die) \
		context->cb.die(context->ctx,"Error at char %d (%1s): %s", p-xml, *p ? p : "\\0", x); \
	else \
		fprintf(stderr,"Error at char %d (%1s): %s\n", p-xml, *p ? p : "\\0", x); \
	goto fault; \
 } while (0)

//Max string lengh for entity name, with trailing '\0'

extern void parse (char * xml, parser_state * state);

#endif
