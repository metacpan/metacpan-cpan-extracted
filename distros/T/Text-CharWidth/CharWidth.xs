#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <wchar.h>

MODULE = Text::CharWidth		PACKAGE = Text::CharWidth		

int
mbwidth(str)
	const char * str
	CODE:
		wchar_t wstr[2];
		int r;
		r = mbstowcs(wstr, str, 1);
		if (r == -1) RETVAL = -1;
		else if (r == 0) RETVAL = 0;
		else RETVAL = wcwidth(wstr[0]);
	OUTPUT:
		RETVAL

int
mbswidth(str)
	const char *str
	CODE:
		int r = 0, len, len2;
		wchar_t wstr[2];

		len = strlen(str);
		RETVAL = 0;
		while (*str != 0) {
			r = mbstowcs(wstr, str, 1);
			if (r == 0 || r == -1) {RETVAL = -1; break;}
			RETVAL += wcwidth(wstr[0]);
			len2 = mblen(str, len+1);
			if (len2 <= 0) {RETVAL = -1; break;}
			str += len2; len -= len2;
		}
	OUTPUT:
		RETVAL

int
mblen(str)
	const char *str
	CODE:
		RETVAL = mblen(str, strlen(str));
	OUTPUT:
		RETVAL

