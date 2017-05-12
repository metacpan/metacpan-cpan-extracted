#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <gperl.h>


MODULE = WWW::WebKit		PACKAGE = WWW::WebKit::XSHelper

void
set_int_return_value(return_value, value)
	gpointer return_value
	int      value
    CODE:
        *(int*)return_value = value;

void
set_string_return_value(return_value, value)
	gpointer return_value
	SV*	 value
    CODE:
	STRLEN len;
	char * pv = SvPVutf8(value, len);
	gchar *copy = g_malloc0((len + 1) * sizeof(char));
	Copy(pv, copy, len, char);
        *((gchar**)return_value) = copy;
