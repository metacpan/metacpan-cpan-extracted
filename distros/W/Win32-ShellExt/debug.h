//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#ifndef _DEBUG_H
#define _DEBUG_H

#ifdef WITH_DEBUG

#define EXTDEBUG_DEV "d:\\log1.txt"

extern void shellext_debug(const char *fmt, ...);
//#define EXTDEBUG(x) shellext_debug x
#define EXTDEBUG(x) \
		{FILE *f=fopen(EXTDEBUG_DEV,"a+"); \
		if(f!=0) { \
			fprintf x ; \
			fclose(f); \
		}}

#else
#define EXTDEBUG(x)
#endif

#endif