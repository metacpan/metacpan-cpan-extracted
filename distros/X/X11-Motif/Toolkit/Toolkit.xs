
/* Copyright 1997, 1998 by Ken Fox */

#include <X11/IntrinsicP.h>

#include "toolkit-api.h"

#undef DEBUG_XT_ARG_LISTS

Widget UxTopLevel = 0;
XtAppContext UxAppContext = 0;

/* BUGS in the resource system:

   4. Don't know if returned resource values are shared or private.  If they
      are private they must be destroyed during garbage collection, otherwise
      they shouldn't -- the widget will do it.  The default should be documented
      and the widget registry should be able to over-ride the default.

*/

/* The Widget may not be an instance of the given WidgetClass.  This is common
   in a CreateWidget call because the widget being created doesn't exist yet.
   The best we can do is provide the parent widget.  In practice, this works
   very well because the widget is only used when a context for acquiring
   server resources is needed.  The widget is also used for garbage collecting
   resources -- how does that interact with always using the parent widget? */

int xt_convert_InArg(Widget w, WidgetClass wc, XtInArg in, XtArgVal *out)
{
    int r = 0;
    XrmValue from;
    STRLEN len;

    from.addr = SvPV(in->src, len);
    from.size = len + 1;

    if (in->res_size < 0) {
	*out = (XtArgVal)from.addr;
	r = 1;
    }
    else {
	XtArgVal very_small_object = 0;
	XrmValue to;

	if (!wc->core_class.class_inited) {
	    /* Force the registration of any per-WidgetClass resource
	       converters by explicitly initializing the widget class. */

	    XtInitializeWidgetClass(wc);
	}

	if (sizeof(XtArgVal) <= in->res_size) {
	    in->dst = &very_small_object;
	}
	else {
	    in->dst = malloc(in->res_size);
	}

	to.size = in->res_size;
	to.addr = in->dst;

	r = XtConvertAndStore(w, XtRString, &from, in->res_type, &to);

	if (r) {
	    if      (to.size == sizeof(XtArgVal))	*out = (XtArgVal)*(XtArgVal *)to.addr;
	    else if (to.size == sizeof(unsigned char))	*out = (XtArgVal)*(unsigned char *)to.addr;
	    else if (to.size == sizeof(unsigned short))	*out = (XtArgVal)*(unsigned short *)to.addr;
	    else if (to.size > sizeof(XtArgVal)) {
		*out = (XtArgVal)to.addr;
	    }
	    else {
		croak("resource converter returned weird size");
	    }
	}

	if (in->dst == &very_small_object) {
	    in->dst = 0;
	}
    }

    return r;
}

Cardinal xt_build_input_arg_list(Widget w, WidgetClass wc, ArgList *arg_list_out, SV **sp, int items)
{
    Cardinal arg_count = 0;
    ArgList arg_list = 0;

    if (items > 0) {
	int i = 0;
	int max = items;

	if (items & 1) {
	    croak("arg_list must be formed of attribute => value pairs");
	}

	arg_list = malloc((items >> 1) * sizeof(Arg));

	while (i < max) {
	    char *name = SvPV(sp[i], na);
	    ++i;

	    if (SvROK(sp[i])) {
		SV *obj = SvRV(sp[i]);
		XtArgVal value;

		if (sv_derived_from(sp[i], "X::Toolkit::InArg")) {
		    /* Use the type information contained in InArg to convert
		       a character string to the right data type using the Xt
		       resource converters. */

		    if (xt_convert_InArg(w, wc, (XtInArg)SvIV(obj), &value)) {
#ifdef DEBUG_XT_ARG_LISTS
			printf("#1.1: arg[%d] = <'%s', 0x%08x>\n", arg_count, name, value);
#endif
			XtSetArg(arg_list[arg_count], name, value); ++arg_count;
		    }
		    else {
			/* If the Xt resource conversion failed, we don't know
			   how to handle the resource so it is just silently
			   ignored. */

#ifdef DEBUG_XT_ARG_LISTS
			printf("#1.2: arg[%d] = <'%s', IGNORING!>\n", arg_count, name);
#endif
		    }
		}
		else {
		    /* If the value is a reference (we assume some type of X
		       object), then it is just passed in as given.  No
		       conversion is attempted and no type checking is
		       performed.  This is dangerous and could lead to crashes
		       in the toolkit library, but we don't have enough
		       information to quickly perform a type check at this
		       point in time.  Not checking the value type has the
		       advantage of allowing us to easily handle "opaque" data
		       types which Perl doesn't fully know about.

		       One check is made for "shared" perl values.  These are
		       plain SV pointers (or boxed unsigned integers) that get
		       stashed in a widget.  Special care must be taken to
		       increment the ref count and schedule a destroy CB to
		       decrement it later.

		       The boxed integers significantly improve performance
		       and memory usage because the values are stashed
		       directly in the widget and will allow the SV to be
		       garbage collected. */

		    char *obj_type = sv_reftype(obj, TRUE);
		    if (obj_type && strEQ(obj_type, "X::shared_perl_value")) {
			SV *sv = (SV *)SvIV(obj);
			if ((int)sv & 1) {
			    value = (XtArgVal)sv;
#ifdef DEBUG_XT_ARG_LISTS
			    printf("#2.1: arg[%d] = <'%s', 0x%08x [BOXED]>\n", arg_count, name, value);
#endif
			}
			else {
			    value = (XtArgVal)SvREFCNT_inc(sv);
#ifdef DEBUG_XT_ARG_LISTS
			    printf("#2.2: arg[%d] = <'%s', 0x%08x [SV *]>\n", arg_count, name, value);
#endif

			    /* FIXME -- DESTROY CB MUST BE SCHEDULED!  This is
			       a bit tricky because we don't have a reference
			       to the widget that the resource is going to be
			       set on yet.  Some sort of queued callback must be
			       created. */
			}
		    }
		    else {
			value = (XtArgVal)SvIV(obj);
#ifdef DEBUG_XT_ARG_LISTS
			printf("#2.3: arg[%d] = <'%s', 0x%08x>\n", arg_count, name, value);
#endif
		    }

		    XtSetArg(arg_list[arg_count], name, value); ++arg_count;
		}
	    }
	    else if (SvIOK(sp[i]) || SvNOK(sp[i])) {
		/* If the value isn't a reference, we check to see if it is a
		   simple numeric value -- usually an enumeration or a screen
		   coordinate.  We have to check both IOK and NOK because it
		   is difficult to predict what Perl will use to store a
		   computation. */

		long value = SvIV(sp[i]);

#ifdef DEBUG_XT_ARG_LISTS
		printf("#3: arg[%d] = <'%s', 0x%08x>\n", arg_count, name, value);
#endif
		XtSetArg(arg_list[arg_count], name, value); ++arg_count;
	    }
	    else {
		/* If anything else was given as a resource value, it has to
		   be ignored because there isn't enough information to know
		   what to do with it.  Other parts of the Toolkit module
		   should ensure that this never happens. */

#ifdef DEBUG_XT_ARG_LISTS
		printf("#4: arg[%d] = <'%s', IGNORING!>\n", arg_count, name);
#endif
	    }

	    ++i;
	}
    }

    *arg_list_out = arg_list;
    return arg_count;
}

HV *res_cvt_table_by_name = 0;
HV *res_cvt_table_by_class = 0;
HV *res_cvt_table_by_type = 0;

void register_resource_converter_by_name(WidgetClass wc, char *res_name,
					 char *package_name, XtOutArgConverter f)
{
    SV **entry;
    char *key;
    STRLEN key_len;

    if (res_cvt_table_by_name == 0) res_cvt_table_by_name = newHV();

    key = wc->core_class.class_name;
    key_len = strlen(key);
    if ((entry = hv_fetch(res_cvt_table_by_name, key, key_len, FALSE)) == 0) {
	entry = hv_store(res_cvt_table_by_name, key, key_len, newRV_noinc((SV *)newHV()), 0);
    }

    if (entry) {
	if (SvROK(*entry))
	{
	    HV *subtable = (HV *)SvRV(*entry);
	    key = res_name;
	    key_len = strlen(key);
	    if ((entry = hv_fetch(subtable, key, key_len, FALSE)) == 0) {
		SV *r = 0;
		if (package_name)
		    r = newSVpv(package_name, strlen(package_name));
		else
		    r = newSViv((I32)f);
		hv_store(subtable, key, key_len, r, 0);
	    }
	    else {
		croak("specific resource converter already registered");
	    }
	}
    }
}

void register_resource_converter_by_class(char *res_class,
					  char *package_name, XtOutArgConverter f)
{
    SV **entry;
    char *key;
    STRLEN key_len;

    if (res_cvt_table_by_class == 0) res_cvt_table_by_class = newHV();

    key = res_class;
    key_len = strlen(key);
    if ((entry = hv_fetch(res_cvt_table_by_class, key, key_len, FALSE)) == 0) {
	SV *r = 0;
	if (package_name)
	    r = newSVpv(package_name, strlen(package_name));
	else
	    r = newSViv((I32)f);
	hv_store(res_cvt_table_by_class, key, key_len, r, 0);
    }
    else {
	croak("class resource converter already registered");
    }
}

void register_resource_converter_by_type(char *res_type,
					 char *package_name, XtOutArgConverter f)
{
    SV **entry;
    char *key;
    STRLEN key_len;

    if (res_cvt_table_by_type == 0) res_cvt_table_by_type = newHV();

    key = res_type;
    key_len = strlen(key);
    if ((entry = hv_fetch(res_cvt_table_by_type, key, key_len, FALSE)) == 0) {
	SV *r = 0;
	if (package_name)
	    r = newSVpv(package_name, strlen(package_name));
	else
	    r = newSViv((I32)f);
	hv_store(res_cvt_table_by_type, key, key_len, r, 0);
    }
    else {
	croak("class resource converter already registered");
    }
}

static SV *cvt_from_String(Widget w, WidgetClass wc, XtOutArg in)
{
    char *r = (char *)in->dst;

    /* when should the String be released?  who owns it?  does the widget
       still own this pointer, or do I?  FIXME */

    return sv_2mortal(newSVpv(r, strlen(r)));
}

static SV *cvt_from_Int(Widget w, WidgetClass wc, XtOutArg in)
{
    int r = (int)in->dst;

    return sv_2mortal(newSViv(r));
}

SV *xt_convert_OutArg(Widget w, WidgetClass wc, XtOutArg in)
{
    XtOutArgConverter f = 0;
    char *package_name = 0;
    SV *r = 0;
    SV **entry;
    char *key;
    STRLEN key_len;

    key = wc->core_class.class_name;
    key_len = strlen(key);
    if ((entry = hv_fetch(res_cvt_table_by_name, key, key_len, FALSE)) != 0) {
	if (SvROK(*entry)) {
	    HV *subtable = (HV *)SvRV(*entry);
	    key = SvPV(in->res_name, key_len);
	    entry = hv_fetch(subtable, key, key_len, FALSE);
	}
    }

    if (entry == 0) {
	key = SvPV(in->res_class, key_len);
	entry = hv_fetch(res_cvt_table_by_class, key, key_len, FALSE);
    }

    if (entry == 0) {
	key = SvPV(in->res_type, key_len);
	entry = hv_fetch(res_cvt_table_by_type, key, key_len, FALSE);
    }

    if (entry) {
	if (SvPOK(*entry)) {
	    r = sv_setref_pv(sv_newmortal(), SvPV(*entry, na), (void *)in->dst);
	}
	else {
	    f = (XtOutArgConverter)SvIV(*entry);
	    r = f(w, wc, in);
	}
    }
    else {
	r = sv_setref_pv(sv_newmortal(), "X::Toolkit::Opaque", (void *)in->dst);
    }

    return r;
}

Cardinal xt_build_output_arg_list(ArgList *arg_list_out, XtOutArgList *arg_info_list_out,
				  SV **sp, int items)
{
    Cardinal arg_count = 0;
    ArgList arg_list = 0;
    XtOutArgList arg_info_list = 0;

    if (items > 0) {
	int i = 0;

	arg_list = malloc(items * sizeof(Arg));
	arg_info_list = malloc(items * sizeof(XtOutArg));

	while (i < items) {
	    if (SvROK(sp[i]) && sv_derived_from(sp[i], "X::Toolkit::OutArg")) {
		XtOutArg out = (XtOutArg)SvIV(SvRV(sp[i]));
		char *res_name = SvPV(out->res_name, na);

		if (out->res_size <= sizeof(XtArgVal)) {
		    out->dst = (XtArgVal)0;
		    XtSetArg(arg_list[arg_count], res_name, &out->dst);
		    arg_info_list[arg_count] = out;
		    ++arg_count;
		}
		else {
		    out->dst = (XtArgVal)malloc(out->res_size);
		    XtSetArg(arg_list[arg_count], res_name, out->dst);
		    arg_info_list[arg_count] = out;
		    ++arg_count;
		}
	    }

	    ++i;
	}
    }

    *arg_list_out = arg_list;
    *arg_info_list_out = arg_info_list;
    return arg_count;
}

static void run_perl_callback(Widget widget, XtPointer client, XtPointer call)
{
    XtPerlClosure closure = (XtPerlClosure)client;

    if (closure) {
	dSP;

	ENTER;
	SAVETMPS;
	PUSHMARK(sp);

	XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)widget));

	if (closure->client_data)
	    XPUSHs(closure->client_data);
	else
	    XPUSHs(&sv_undef);

	if (closure->call_type) {
	    char *package = SvPV(SvRV(closure->call_type), na);
	    XPUSHs(sv_setref_pv(sv_newmortal(), package, (void *)call));
	}

	PUTBACK;

	perl_call_sv(closure->proc, G_VOID|G_DISCARD);

	SPAGAIN;
	FREETMPS;
	LEAVE;
    }
}

static void destroy_perl_callback(Widget widget, XtPointer client, XtPointer call)
{
    XtPerlClosure closure = (XtPerlClosure)client;

    if (closure && closure->proc) {
	SvREFCNT_dec(closure->proc);

	if (closure->client_data)
	    SvREFCNT_dec(closure->client_data);

	if (closure->call_type)
	    SvREFCNT_dec(closure->call_type);

	closure->proc = 0;
	free(closure);
    }
}

static void run_and_destroy_perl_callback(Widget widget, XtPointer client, XtPointer call)
{
    run_perl_callback(widget, client, call);
    destroy_perl_callback(widget, client, call);
}




MODULE = X11::Toolkit	PACKAGE = X::Toolkit

PROTOTYPES: ENABLE

void
initialize(app_class)
	char *		app_class
	PREINIT:
	    int argc = 0;
	    char **argv = 0;
	PPCODE:
	    UxTopLevel = XtAppInitialize(&UxAppContext, app_class, 0, 0, &argc, argv, 0, 0, 0);
	    if (GIMME == G_ARRAY) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)UxTopLevel));
		XPUSHs(sv_setref_pv(sv_newmortal(), XtAppContext_Package, (void *)UxAppContext));
	    }
	    else {
		XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)UxTopLevel));
	    }

void
register_with_application(top)
	Widget		top
	CODE:
	    UxTopLevel = top;
	    UxAppContext = XtWidgetToApplicationContext(top);

void
toplevel()
	PPCODE:
	    if (UxTopLevel) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)UxTopLevel));
	    }

void
context()
	PPCODE:
	    if (UxAppContext) {
		XPUSHs(sv_setref_pv(sv_newmortal(), XtAppContext_Package, (void *)UxAppContext));
	    }

Widget
search_from_toplevel(name)
	char *		name
	CODE:
	    if (!UxTopLevel) croak("no toplevel");
	    RETVAL = XtNameToWidget(UxTopLevel, name);
	    if (!RETVAL) croak("couldn't find a widget with that name");
	OUTPUT:
	    RETVAL

Widget
search_from_parent(parent, name)
	Widget	parent
	char *		name
	CODE:
	    RETVAL = XtNameToWidget(parent, name);
	    if (!RETVAL) croak("couldn't find a widget with that name");
	OUTPUT:
	    RETVAL




MODULE = X11::Toolkit	PACKAGE = X::Toolkit::InArg

XtInArg
new(src, res_type_sv, res_size, just_use_SvPV)
	SV *		src
	SV *		res_type_sv
	int		res_size
	int		just_use_SvPV;
	PREINIT:
	    char *res_type;
	    STRLEN len;
	CODE:
	    RETVAL = (XtInArg)malloc(sizeof(struct XtInArgStruct));
	    RETVAL->src = newSVsv(src);
	    RETVAL->dst = 0;
	    if (just_use_SvPV) {
		RETVAL->res_type = 0;
		RETVAL->res_size = -1;
	    }
	    else {
		res_type = SvPV(res_type_sv, len);
		RETVAL->res_type = malloc(len + 1);
		strcpy(RETVAL->res_type, res_type);
		RETVAL->res_size = res_size;
	    }
	OUTPUT:
	    RETVAL

void
DESTROY(self)
	XtInArg		self
	PPCODE:
	    if (self->src) {
		SvREFCNT_dec(self->src);
		self->src = 0;
	    }
	    if (self->res_type) {
		free(self->res_type);
		self->res_type = 0;
	    }
	    if (self->dst) {
		free(self->dst);
		self->dst = 0;
	    }
	    free(self);





MODULE = X11::Toolkit	PACKAGE = X::Toolkit::OutArg

XtOutArg
new(res_name, res_class, res_type, res_size, hints)
	SV *		res_name
	SV *		res_class
	SV *		res_type
	int		res_size
	char *		hints
	CODE:
	    RETVAL = (XtOutArg)malloc(sizeof(struct XtOutArgStruct));
	    RETVAL->res_name = newSVsv(res_name);
	    RETVAL->res_class = newSVsv(res_class);
	    RETVAL->res_type = newSVsv(res_type);
	    RETVAL->res_size = res_size;
	    RETVAL->res_signed = (*hints == 'u') ? 0 : 1;
	    RETVAL->dst = 0;
	OUTPUT:
	    RETVAL

void
DESTROY(self)
	XtOutArg	self
	PPCODE:
	    if (self->res_name) {
		SvREFCNT_dec(self->res_name);
		SvREFCNT_dec(self->res_class);
		SvREFCNT_dec(self->res_type);
		if (self->res_size > sizeof(XtArgVal) && self->dst) free((void *)self->dst);
		self->res_name = 0;
		free(self);
	    }





MODULE = X11::Toolkit	PACKAGE = X::Toolkit::Widget

long
ID(self)
	Widget		self
	CODE:
	    RETVAL = (unsigned long)self >> 2;
	OUTPUT:
	    RETVAL

int
equal(self, other)
	Widget		self
	Widget		other
	CODE:
	    RETVAL = (self == other);
	OUTPUT:
	    RETVAL

double
width_pixels_per_mm(self)
	Widget		self
	PREINIT:
	    Screen *screen;
	CODE:
	    screen = XtScreen(self);
	    if (screen)
		RETVAL = WidthOfScreen(screen) / WidthMMOfScreen(screen);
	    else
		RETVAL = 100 / 25.4;
	OUTPUT:
	    RETVAL

double
height_pixels_per_mm(self)
	Widget		self
	PREINIT:
	    Screen *screen;
	CODE:
	    screen = XtScreen(self);
	    if (screen)
		RETVAL = HeightOfScreen(screen) / HeightMMOfScreen(screen);
	    else
		RETVAL = 100 / 25.4;
	OUTPUT:
	    RETVAL

void
XtParent(self)
	Widget		self
	PPCODE:
	    if (XtParent(self)) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)XtParent(self)));
	    }

void
XtChildren(self)
	Widget		self
	PPCODE:
	    if (XtIsComposite(self)) {
		CompositeWidget composite = (CompositeWidget)self;
		int i;
		for (i = 0; i < composite->composite.num_children; ++i) {
		    XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package,
					(void *)composite->composite.children[i]));
		}
	    }

void
XtShell(self)
	Widget		self
	PPCODE:
	    while (self && !XtIsShell(self)) {
		self = XtParent(self);
	    }
	    if (self) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, (void *)self));
	    }

int
XtIsWidget(self)
	SV *		self
	CODE:
	    if (sv_derived_from(self, Widget_Package)) {
		IV tmp_ = SvIV((SV*)SvRV(self));
		RETVAL = XtIsWidget((Widget)tmp_);
	    }
	    else
	    {
		RETVAL = 0;
	    }
	OUTPUT:
	    RETVAL

int
XtIsComposite(self)
	Widget		self

int
XtIsConstraint(self)
	Widget		self

int
XtIsShell(self)
	Widget		self

int
XtIsOverrideShell(self)
	Widget		self

int
XtIsWMShell(self)
	Widget		self

int
XtIsVendorShell(self)
	Widget		self

int
XtIsTransientShell(self)
	Widget		self

int
XtIsTopLevelShell(self)
	Widget		self

int
XtIsApplicationShell(self)
	Widget		self

void
priv_XtAddCallback(self, name, proc, call_type, client_data = 0)
	Widget		self
	char *		name
	SV *		proc
	SV *		call_type
	SV *		client_data
	CODE:
	    if (SvROK(proc) && SvTYPE(SvRV(proc)) == SVt_PVCV) {
		XtPerlClosure closure = (XtPerlClosure)malloc(sizeof(struct XtPerlClosureStruct));
		closure->proc = newSVsv(proc);
		closure->call_type = SvROK(call_type) ? newSVsv(call_type) : 0;
		closure->client_data = (client_data) ? newSVsv(client_data) : 0;
		if (strcmp(name, XtNdestroyCallback) == 0) {
		    XtAddCallback(self, name, run_and_destroy_perl_callback, closure);
		}
		else {
		    XtAddCallback(self, name, run_perl_callback, closure);
		    XtAddCallback(self, XtNdestroyCallback, destroy_perl_callback, closure);
		}
	    }
	    else {
		croak("callback must be a subroutine");
	    }

void
priv_XtGetValues(self, ...)
	Widget		self
	PREINIT:
	    ArgList arg_list = 0;
	    XtOutArgList arg_info_list = 0;
	    Cardinal arg_list_len = 0;
	    Cardinal i;
	PPCODE:
	    arg_list_len = xt_build_output_arg_list(&arg_list, &arg_info_list, &ST(1), items - 1);
	    if (arg_list) {
		XtGetValues(self, arg_list, arg_list_len);
		for (i = 0; i < arg_list_len; ++i) {
		    if (arg_info_list[i]->res_size == sizeof(unsigned char)) {
			unsigned char v = *(unsigned char *)&(arg_info_list[i]->dst);
			XPUSHs(sv_2mortal(newSViv(v)));
		    }
		    else if (arg_info_list[i]->res_size == sizeof(short)) {
			I32 v;
			if (arg_info_list[i]->res_signed) {
			    v = *(short *)&(arg_info_list[i]->dst);
			}
			else {
			    v = *(unsigned short *)&(arg_info_list[i]->dst);
			}
			XPUSHs(sv_2mortal(newSViv(v)));
		    }
		    else {
			XPUSHs(xt_convert_OutArg(self, XtClass(self), arg_info_list[i]));
		    }
		}
		free(arg_list);
		free(arg_info_list);
	    }

void
XtMapWidget(widget)
	Widget		widget

void
XtUnmapWidget(widget)
	Widget		widget


		 

MODULE = X11::Toolkit	PACKAGE = X::Toolkit

# ----------------------------------------------------------------------
# The next section was derived from an automatically generated XS
# template.

# -- BEGIN list-raw-funs OUTPUT --
void
XtAddExposureToRegion(event, region)
	XEvent *		event
	Region			region

Widget
priv_XtAppCreateShell(application_name, application_class, widget_class, display, ...)
	char *			application_name
	char *			application_class
	WidgetClass		widget_class
	Display *		display
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(0, widget_class, &arg_list, &ST(4), items - 4);
	    RETVAL = XtAppCreateShell(application_name, application_class, widget_class, display, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Boolean
XtCallConverter(dpy, converter, args, num_args, from, to_in_out, cache_ref_return)
	Display *		dpy
	XtTypeConverter		converter
	XrmValuePtr		args
	Cardinal		num_args
	XrmValuePtr		from
	XrmValue *		to_in_out
	XtCacheRef *		cache_ref_return

void
XtCloseDisplay(dpy)
	Display *		dpy

void
XtConvertCase(dpy, keysym, lower_return, upper_return)
	Display *		dpy
	KeySym			keysym
	KeySym *		lower_return
	KeySym *		upper_return

XtAppContext
XtCreateApplicationContext()


Widget
priv_XtCreateManagedWidget(name, widget_class, parent, ...)
	char *			name
	WidgetClass		widget_class
	Widget			parent
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, widget_class, &arg_list, &ST(3), items - 3);
	    RETVAL = XtCreateManagedWidget(name, widget_class, parent, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XtCreatePopupShell(name, widgetClass, parent, ...)
	char *			name
	WidgetClass		widgetClass
	Widget			parent
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, widgetClass, &arg_list, &ST(3), items - 3);
	    RETVAL = XtCreatePopupShell(name, widgetClass, parent, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XtCreateWidget(name, widget_class, parent, ...)
	char *			name
	WidgetClass		widget_class
	Widget			parent
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, widget_class, &arg_list, &ST(3), items - 3);
	    RETVAL = XtCreateWidget(name, widget_class, parent, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

XrmDatabase
XtDatabase(dpy)
	Display *		dpy

Boolean
XtDispatchEvent(event)
	XEvent *		event

void
XtDisplayStringConversionWarning(dpy, from_value, to_type)
	Display *		dpy
	char *			from_value
	char *			to_type

XtAppContext
XtDisplayToApplicationContext(dpy)
	Display *		dpy

String
XtFindFile(path, substitutions, num_substitutions, predicate)
	char *			path
	Substitution		substitutions
	Cardinal		num_substitutions
	XtFilePredicate		predicate

KeySym
XtGetActionKeysym(event, modifiers_return)
	XEvent *		event
	Modifiers *		modifiers_return

KeySym *
XtGetKeysymTable(dpy, min_keycode_return, keysyms_per_keycode_return)
	Display *		dpy
	KeyCode *		min_keycode_return
	int  			&keysyms_per_keycode_return
	OUTPUT:
	    RETVAL
	    keysyms_per_keycode_return

int
XtGetMultiClickTime(dpy)
	Display *		dpy

void
XtInitializeWidgetClass(widget_class)
	WidgetClass		widget_class

void
XtKeysymToKeycodeList(dpy, keysym, keycodes_return, keycount_return)
	Display *		dpy
	KeySym			keysym
	KeyCode **		keycodes_return
	Cardinal *		keycount_return

Time
XtLastTimestampProcessed(dpy)
	Display *		dpy

void
XtManageChildren(children, num_children)
	WidgetList		children
	Cardinal		num_children

XtAccelerators
XtParseAcceleratorTable(source)
	char *			source

XtTranslations
XtParseTranslationTable(table)
	char *			table

void
XtRegisterCaseConverter(dpy, proc, start, stop)
	Display *		dpy
	XtCaseProc		proc
	KeySym			start
	KeySym			stop

void
XtRegisterGrabAction(action_proc, owner_events, event_mask, pointer_mode, keyboard_mode)
	XtActionProc		action_proc
	int			owner_events
	unsigned int		event_mask
	int			pointer_mode
	int			keyboard_mode

void
XtRemoveActionHook(id)
	XtActionHookId		id

void
XtRemoveInput(id)
	XtInputId		id

void
XtRemoveTimeOut(timer)
	XtIntervalId		timer

void
XtRemoveWorkProc(id)
	XtWorkProcId		id

String
XtResolvePathname(dpy, type, filename, suffix, path, substitutions, num_substitutions, predicate)
	Display *		dpy
	char *			type
	char *			filename
	char *			suffix
	char *			path
	Substitution		substitutions
	Cardinal		num_substitutions
	XtFilePredicate		predicate

XrmDatabase
XtScreenDatabase(screen)
	Screen *		screen

void
XtSetKeyTranslator(dpy, proc)
	Display *		dpy
	XtKeyProc		proc

void
XtSetMultiClickTime(dpy, milliseconds)
	Display *		dpy
	int			milliseconds

void
XtSetTypeConverter(from_type, to_type, converter, convert_args, num_args, cache_type, destructor)
	char *			from_type
	char *			to_type
	XtTypeConverter		converter
	XtConvertArgList	convert_args
	Cardinal		num_args
	XtCacheType		cache_type
	XtDestructor		destructor

void
XtToolkitInitialize()


void
XtTranslateKey(dpy, keycode, modifiers, modifiers_return, keysym_return)
	Display *		dpy
	unsigned int		keycode
	Modifiers		modifiers
	Modifiers *		modifiers_return
	KeySym *		keysym_return

void
XtTranslateKeycode(dpy, keycode, modifiers, modifiers_return, keysym_return)
	Display *		dpy
	unsigned int		keycode
	Modifiers		modifiers
	Modifiers *		modifiers_return
	KeySym *		keysym_return

void
XtUnmanageChildren(children, num_children)
	WidgetList		children
	Cardinal		num_children

Widget
XtWindowToWidget(display, window)
	Display *		display
	Window			window

MODULE = X11::Toolkit	PACKAGE = X::Toolkit::Widget

void
XtAddEventHandler(widget, event_mask, nonmaskable, proc, closure)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure

void
XtAddGrab(widget, exclusive, spring_loaded)
	Widget			widget
	int			exclusive
	int			spring_loaded

void
XtAddRawEventHandler(widget, event_mask, nonmaskable, proc, closure)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure

GC
XtAllocateGC(widget, depth, valueMask, values, dynamicMask, unusedMask)
	Widget			widget
	Cardinal		depth
	XtGCMask		valueMask
	XGCValues *		values
	XtGCMask		dynamicMask
	XtGCMask		unusedMask

void
XtAugmentTranslations(widget, translations)
	Widget			widget
	XtTranslations		translations

EventMask
XtBuildEventMask(widget)
	Widget			widget

Boolean
XtCallAcceptFocus(widget, time)
	Widget			widget
	Time *			time

void
XtCallActionProc(widget, action, event, params, num_params)
	Widget			widget
	char *			action
	XEvent *		event
	String *		params
	Cardinal		num_params

void
XtCallCallbackList(widget, callbacks, call_data)
	Widget			widget
	XtCallbackList		callbacks
	XtPointer		call_data

void
XtCallCallbacks(widget, callback_name, call_data)
	Widget			widget
	char *			callback_name
	XtPointer		call_data

void
XtCallbackExclusive(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

void
XtCallbackNone(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

void
XtCallbackNonexclusive(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

void
XtCallbackPopdown(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

void
XtCallbackReleaseCacheRef(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

void
XtCallbackReleaseCacheRefList(widget, closure, call_data)
	Widget			widget
	XtPointer		closure
	XtPointer		call_data

WidgetClass
XtClass(object)
	Widget			object

void
XtConfigureWidget(widget, x, y, width, height, border_width)
	Widget			widget
	int			x
	int			y
	unsigned int		width
	unsigned int		height
	unsigned int		border_width

Boolean
XtConvertAndStore(widget, from_type, from, to_type, to_in_out)
	Widget			widget
	char *			from_type
	XrmValue *		from
	char *			to_type
	XrmValue *		to_in_out

void
XtCreateWindow(widget, window_class, visual, value_mask, attributes)
	Widget			widget
	unsigned int		window_class
	Visual *		visual
	XtValueMask		value_mask
	XSetWindowAttributes *	attributes

void
XtDestroyWidget(widget)
	Widget			widget

void
XtDisownSelection(widget, selection, time)
	Widget			widget
	Atom			selection
	Time			time

Display *
XtDisplay(widget)
	Widget			widget

Display *
XtDisplayOfObject(object)
	Widget			object

GC
XtGetGC(widget, valueMask, values)
	Widget			widget
	XtGCMask		valueMask
	XGCValues *		values

XSelectionRequestEvent *
XtGetSelectionRequest(widget, selection, request_id)
	Widget			widget
	Atom			selection
	XtRequestId		request_id

void
XtGetSelectionValue(widget, selection, target, callback, closure, time)
	Widget			widget
	Atom			selection
	Atom			target
	XtSelectionCallbackProc	callback
	XtPointer		closure
	Time			time

void
XtGetSelectionValueIncremental(widget, selection, target, selection_callback, client_data, time)
	Widget			widget
	Atom			selection
	Atom			target
	XtSelectionCallbackProc	selection_callback
	XtPointer		client_data
	Time			time

void
XtGetSelectionValues(widget, selection, targets, count, callback, closures, time)
	Widget			widget
	Atom			selection
	Atom *			targets
	int			count
	XtSelectionCallbackProc	callback
	XtPointer *		closures
	Time			time

void
XtGetSelectionValuesIncremental(widget, selection, targets, count, callback, client_data, time)
	Widget			widget
	Atom			selection
	Atom *			targets
	int			count
	XtSelectionCallbackProc	callback
	XtPointer *		client_data
	Time			time

void
XtGrabButton(widget, button, modifiers, owner_events, event_mask, pointer_mode, keyboard_mode, confine_to, cursor)
	Widget			widget
	int			button
	Modifiers		modifiers
	int			owner_events
	unsigned int		event_mask
	int			pointer_mode
	int			keyboard_mode
	Window			confine_to
	Cursor			cursor

void
XtGrabKey(widget, keycode, modifiers, owner_events, pointer_mode, keyboard_mode)
	Widget			widget
	unsigned int		keycode
	Modifiers		modifiers
	int			owner_events
	int			pointer_mode
	int			keyboard_mode

int
XtGrabKeyboard(widget, owner_events, pointer_mode, keyboard_mode, time)
	Widget			widget
	int			owner_events
	int			pointer_mode
	int			keyboard_mode
	Time			time

int
XtGrabPointer(widget, owner_events, event_mask, pointer_mode, keyboard_mode, confine_to, cursor, time)
	Widget			widget
	int			owner_events
	unsigned int		event_mask
	int			pointer_mode
	int			keyboard_mode
	Window			confine_to
	Cursor			cursor
	Time			time

XtCallbackStatus
XtHasCallbacks(widget, callback_name)
	Widget			widget
	char *			callback_name

void
XtInsertEventHandler(widget, event_mask, nonmaskable, proc, closure, position)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure
	XtListPosition		position

void
XtInsertRawEventHandler(widget, event_mask, nonmaskable, proc, closure, position)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure
	XtListPosition		position

void
XtInstallAccelerators(destination, source)
	Widget			destination
	Widget			source

void
XtInstallAllAccelerators(destination, source)
	Widget			destination
	Widget			source

Boolean
XtIsManaged(rectobj)
	Widget			rectobj

Boolean
XtIsObject(object)
	Widget			object

Boolean
XtIsRealized(widget)
	Widget			widget

Boolean
XtIsSensitive(widget)
	Widget			widget

Boolean
XtIsSubclass(widget, widgetClass)
	Widget			widget
	WidgetClass		widgetClass

XtGeometryResult
XtMakeGeometryRequest(widget, request, reply_return)
	Widget			widget
	XtWidgetGeometry *	request
	XtWidgetGeometry *	reply_return

XtGeometryResult
XtMakeResizeRequest(widget, width, height, width_return, height_return)
	Widget			widget
	unsigned int		width
	unsigned int		height
	Dimension *		width_return
	Dimension *		height_return

void
XtManageChild(child)
	Widget			child

void
XtMenuPopupAction(widget, event, params, num_params)
	Widget			widget
	XEvent *		event
	String *		params
	Cardinal *		num_params

void
XtMoveWidget(widget, x, y)
	Widget			widget
	int			x
	int			y

String
XtName(object)
	Widget			object

Widget
XtNameToWidget(reference, names)
	Widget			reference
	char *			names

void
XtOverrideTranslations(widget, translations)
	Widget			widget
	XtTranslations		translations

Boolean
XtOwnSelection(widget, selection, time, convert, lose, done)
	Widget			widget
	Atom			selection
	Time			time
	XtConvertSelectionProc	convert
	XtLoseSelectionProc	lose
	XtSelectionDoneProc	done

Boolean
XtOwnSelectionIncremental(widget, selection, time, convert_callback, lose_callback, done_callback, cancel_callback, client_data)
	Widget			widget
	Atom			selection
	Time			time
	XtConvertSelectionIncrProc	convert_callback
	XtLoseSelectionIncrProc	lose_callback
	XtSelectionDoneIncrProc	done_callback
	XtCancelConvertSelectionProc	cancel_callback
	XtPointer		client_data

void
XtPopdown(popup_shell)
	Widget			popup_shell

void
XtPopup(popup_shell, grab_kind)
	Widget			popup_shell
	XtGrabKind		grab_kind

void
XtPopupSpringLoaded(popup_shell)
	Widget			popup_shell

XtGeometryResult
XtQueryGeometry(widget, intended, preferred_return)
	Widget			widget
	XtWidgetGeometry *	intended
	XtWidgetGeometry *	preferred_return

void
XtRealizeWidget(widget)
	Widget			widget

void
XtReleaseGC(object, gc)
	Widget			object
	GC			gc

void
XtRemoveAllCallbacks(widget, callback_name)
	Widget			widget
	char *			callback_name

void
XtRemoveCallback(widget, callback_name, callback, closure)
	Widget			widget
	char *			callback_name
	XtCallbackProc		callback
	XtPointer		closure

void
XtRemoveCallbacks(widget, callback_name, callbacks)
	Widget			widget
	char *			callback_name
	XtCallbackList		callbacks

void
XtRemoveEventHandler(widget, event_mask, nonmaskable, proc, closure)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure

void
XtRemoveGrab(widget)
	Widget			widget

void
XtRemoveRawEventHandler(widget, event_mask, nonmaskable, proc, closure)
	Widget			widget
	EventMask		event_mask
	int			nonmaskable
	XtEventHandler		proc
	XtPointer		closure

void
XtResizeWidget(widget, width, height, border_width)
	Widget			widget
	unsigned int		width
	unsigned int		height
	unsigned int		border_width

void
XtResizeWindow(widget)
	Widget			widget

Screen *
XtScreen(widget)
	Widget			widget

Screen *
XtScreenOfObject(object)
	Widget			object

void
XtSetKeyboardFocus(subtree, descendent)
	Widget			subtree
	Widget			descendent

void
XtSetMappedWhenManaged(widget, mapped_when_managed)
	Widget			widget
	int			mapped_when_managed

void
XtSetSensitive(widget, sensitive)
	Widget			widget
	int			sensitive

void
priv_XtSetValues(widget, ...)
	Widget			widget
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(widget, XtClass(widget), &arg_list, &ST(1), items - 1);
	    XtSetValues(widget, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);

void
XtSetWMColormapWindows(widget, list, count)
	Widget			widget
	Widget *		list
	Cardinal		count

WidgetClass
XtSuperclass(object)
	Widget			object

void
XtTranslateCoords(widget, x, y, rootx_return, rooty_return)
	Widget			widget
	int			x
	int			y
	Position *		rootx_return
	Position *		rooty_return

void
XtUngrabButton(widget, button, modifiers)
	Widget			widget
	unsigned int		button
	Modifiers		modifiers

void
XtUngrabKey(widget, keycode, modifiers)
	Widget			widget
	unsigned int		keycode
	Modifiers		modifiers

void
XtUngrabKeyboard(widget, time)
	Widget			widget
	Time			time

void
XtUngrabPointer(widget, time)
	Widget			widget
	Time			time

void
XtUninstallTranslations(widget)
	Widget			widget

void
XtUnmanageChild(child)
	Widget			child

XtAppContext
XtWidgetToApplicationContext(widget)
	Widget			widget

Window
XtWindow(widget)
	Widget			widget

Window
XtWindowOfObject(object)
	Widget			object

MODULE = X11::Toolkit	PACKAGE = X::Toolkit::Context

XtActionHookId
XtAppAddActionHook(app_context, proc, client_data)
	XtAppContext		app_context
	XtActionHookProc	proc
	XtPointer		client_data

void
XtAppAddActions(app_context, actions, num_actions)
	XtAppContext		app_context
	XtActionList		actions
	Cardinal		num_actions

XtInputId
XtAppAddInput(app_context, source, condition, proc, closure)
	XtAppContext		app_context
	int			source
	XtPointer		condition
	XtInputCallbackProc	proc
	XtPointer		closure

XtIntervalId
XtAppAddTimeOut(app_context, interval, proc, closure)
	XtAppContext		app_context
	unsigned long		interval
	XtTimerCallbackProc	proc
	XtPointer		closure

XtWorkProcId
XtAppAddWorkProc(app_context, proc, closure)
	XtAppContext		app_context
	XtWorkProc		proc
	XtPointer		closure

void
XtAppError(app_context, message)
	XtAppContext		app_context
	char *			message

void
XtAppErrorMsg(app_context, name, type, class, def, params, num_params)
	XtAppContext		app_context
	char *			name
	char *			type
	char *			class
	char *			def
	String *		params
	Cardinal *		num_params

XrmDatabase *
XtAppGetErrorDatabase(app_context)
	XtAppContext		app_context

void
XtAppGetErrorDatabaseText(app_context, name, type, class, def, buffer_return, nbytes, database)
	XtAppContext		app_context
	char *			name
	char *			type
	char *			class
	char *			def
	String			buffer_return
	int			nbytes
	XrmDatabase		database

unsigned long
XtAppGetSelectionTimeout(app_context)
	XtAppContext		app_context

Widget
priv_XtAppInitialize(app_context_return, application_class, options, num_options, argc_in_out, argv_in_out, fallback_resources, ...)
	XtAppContext *		app_context_return
	char *			application_class
	XrmOptionDescList	options
	Cardinal		num_options
	int *			argc_in_out
	String *		argv_in_out
	String *		fallback_resources
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(0, 0, &arg_list, &ST(7), items - 7);
	    RETVAL = XtAppInitialize(app_context_return, application_class, options, num_options, argc_in_out, argv_in_out, fallback_resources, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

void
XtAppMainLoop(app_context)
	XtAppContext		app_context

XtInputMask
XtAppPending(app_context)
	XtAppContext		app_context

void
XtAppProcessEvent(app_context, mask)
	XtAppContext		app_context
	XtInputMask		mask

void
XtAppReleaseCacheRefs(app_context, cache_ref)
	XtAppContext		app_context
	XtCacheRef *		cache_ref

XtErrorHandler
XtAppSetErrorHandler(app_context, handler)
	XtAppContext		app_context
	XtErrorHandler		handler

XtErrorMsgHandler
XtAppSetErrorMsgHandler(app_context, handler)
	XtAppContext		app_context
	XtErrorMsgHandler	handler

void
XtAppSetFallbackResources(app_context, specification_list)
	XtAppContext		app_context
	String *		specification_list

void
XtAppSetSelectionTimeout(app_context, timeout)
	XtAppContext		app_context
	unsigned long		timeout

void
XtAppSetTypeConverter(app_context, from_type, to_type, converter, convert_args, num_args, cache_type, destructor)
	XtAppContext		app_context
	char *			from_type
	char *			to_type
	XtTypeConverter		converter
	XtConvertArgList	convert_args
	Cardinal		num_args
	XtCacheType		cache_type
	XtDestructor		destructor

XtErrorHandler
XtAppSetWarningHandler(app_context, handler)
	XtAppContext		app_context
	XtErrorHandler		handler

XtErrorMsgHandler
XtAppSetWarningMsgHandler(app_context, handler)
	XtAppContext		app_context
	XtErrorMsgHandler	handler

void
XtAppWarning(app_context, message)
	XtAppContext		app_context
	char *			message

void
XtAppWarningMsg(app_context, name, type, class, def, params, num_params)
	XtAppContext		app_context
	char *			name
	char *			type
	char *			class
	char *			def
	String *		params
	Cardinal *		num_params

void
XtDestroyApplicationContext(app_context)
	XtAppContext		app_context

void
XtDisplayInitialize(app_context, dpy, application_name, application_class, options, num_options, argc, argv)
	XtAppContext		app_context
	Display *		dpy
	char *			application_name
	char *			application_class
	XrmOptionDescRec *	options
	Cardinal		num_options
	int *			argc
	char **			argv

Display *
XtOpenDisplay(app_context, display_string, application_name, application_class, options, num_options, argc, argv)
	XtAppContext		app_context
	char *			display_string
	char *			application_name
	char *			application_class
	XrmOptionDescRec *	options
	Cardinal		num_options
	int *			argc
	char **			argv

XtLanguageProc
XtSetLanguageProc(app_context, proc, client_data)
	XtAppContext		app_context
	XtLanguageProc		proc
	XtPointer		client_data

# -- END list-raw-funs OUTPUT --




MODULE = X11::Toolkit	PACKAGE = X::Toolkit::WidgetClass

WidgetClass
parent(widget_class)
	WidgetClass	widget_class
	CODE:
	    RETVAL = widget_class->core_class.superclass;
	OUTPUT:
	    RETVAL

char *
name(widget_class)
	WidgetClass	widget_class
	CODE:
	    RETVAL = widget_class->core_class.class_name;
	OUTPUT:
	    RETVAL

int
equal(self, other)
	WidgetClass	self
	WidgetClass	other
	CODE:
	    RETVAL = (self == other);
	OUTPUT:
	    RETVAL

void
resources(widget_class)
	WidgetClass	widget_class
	PREINIT:
	    int i, num;
	PPCODE:
	    while (widget_class) {
		num = widget_class->core_class.num_resources;
		EXTEND(sp, num * 4);
		if (!widget_class->core_class.class_inited) {
		    XtResourceList list = widget_class->core_class.resources;
		    for (i = 0; i < num; ++i) {
#ifdef HAS_FAST_QUARKS
			char *resource_name = (char *)_XQstring(list[i].resource_name);
			char *resource_class = (char *)_XQstring(list[i].resource_class);
			char *resource_type = (char *)_XQstring(list[i].resource_type);
#else
			char *resource_name = list[i].resource_name;
			char *resource_class = list[i].resource_class;
			char *resource_type = list[i].resource_type;
#endif
			if (resource_name && resource_class && resource_type)
			{
			    PUSHs(sv_2mortal(newSVpv(resource_name, 0)));
			    PUSHs(sv_2mortal(newSVpv(resource_class, 0)));
			    PUSHs(sv_2mortal(newSVpv(resource_type, 0)));
			    PUSHs(sv_2mortal(newSViv(list[i].resource_size)));
			}
		    }
		}
		else {
		    croak("can't read an initialized widget class");
		}
		widget_class = widget_class->core_class.superclass;
	    }

void
constraint_resources(widget_class)
	WidgetClass	widget_class
	PREINIT:
	    int i, num;
	    WidgetClass c_parent;
	PPCODE:
	    for (c_parent = widget_class; c_parent; c_parent = c_parent->core_class.superclass) {
		if (c_parent == constraintWidgetClass) break;
	    }
	    if (c_parent)
	    {
		ConstraintWidgetClass c_widget_class = (ConstraintWidgetClass)widget_class;
		while ((WidgetClass)c_widget_class != c_parent) {
		    num = c_widget_class->constraint_class.num_resources;
		    EXTEND(sp, num * 3);
		    if (!c_widget_class->core_class.class_inited) {
			XtResourceList list = c_widget_class->constraint_class.resources;
			for (i = 0; i < num; ++i) {
#ifdef HAS_FAST_QUARKS
			    char *resource_name = (char *)_XQstring(list[i].resource_name);
			    char *resource_class = (char *)_XQstring(list[i].resource_class);
			    char *resource_type = (char *)_XQstring(list[i].resource_type);
#else
			    char *resource_name = list[i].resource_name;
			    char *resource_class = list[i].resource_class;
			    char *resource_type = list[i].resource_type;
#endif
			    if (resource_name && resource_class && resource_type)
			    {
				PUSHs(sv_2mortal(newSVpv(resource_name, 0)));
				PUSHs(sv_2mortal(newSVpv(resource_class, 0)));
				PUSHs(sv_2mortal(newSVpv(resource_type, 0)));
				PUSHs(sv_2mortal(newSViv(list[i].resource_size)));
			    }
			}
		    }
		    else {
			croak("can't read an initialized widget class");
		    }
		    c_widget_class = (ConstraintWidgetClass)c_widget_class->core_class.superclass;
		}
	    }



MODULE = X11::Toolkit	PACKAGE = X::Toolkit::Context

XEvent *
XtAppNextEvent(app_context)
	XtAppContext		app_context
	PREINIT:
	    static XEvent e;
	CODE:
	    XtAppNextEvent(app_context, &e);
	    RETVAL = &e;
	OUTPUT:
	    RETVAL

void
XtAppPeekEvent(app_context)
	XtAppContext		app_context
	PREINIT:
	    static XEvent e;
	    SV *sv;
	PPCODE:
	    if (XtAppPeekEvent(app_context, &e))
	    {
		sv = sv_newmortal();
		sv_setref_pv(sv, XEventPtr_Package(e.type), (void *)&e);
		PUSHs(sv);
	    }



MODULE = X11::Toolkit	PACKAGE = X::Toolkit::Opaque



MODULE = X11::Toolkit	PACKAGE = X::shared_perl_value

void
new(class_name, value)
	char *		class_name
	SV *		value
	PPCODE:
	    if (SvIOK(value) && (unsigned int)SvIV(value) < PERL_INT_MAX) {
		/* Any integer >= 0 and < PERL_INT_MAX can be "boxed" or marked
		   as a non-pointer.  This is a very useful optimization because it
		   means that the SV itself does not need to be stored or garbage
		   collected later. */

		XPUSHs(sv_setref_iv(sv_newmortal(), "X::shared_perl_value", (SvIV(value) << 1) | 1));
	    }
	    else {
		/* A copy of the input value is made so that aliasing does not occur.
		   The term "share" in this context does not mean sharing a single Perl
		   value, but allowing C to hold a Perl value for later use in Perl.  If
		   value sharing is required, pass in a reference to a Perl value. */

		SV *copy = newSVsv(value);
		XPUSHs(sv_setref_pv(sv_newmortal(), "X::shared_perl_value", (void *)copy));
	    }

void
DESTROY(self)
	SV *		self
	PPCODE:
	    if (SvROK(self)) {
		SV *value = (SV *)SvIV(SvRV(self));
		if ((int)value & 1) {
		    /* A "boxed" value is an immediate integer and don't need to
		       be garbage collected. */
		}
		else {
		    SvREFCNT_dec(value);
		}
	    }



BOOT:
    register_resource_converter_by_type("String",	0, cvt_from_String);
    register_resource_converter_by_type("Int",		0, cvt_from_Int);
    register_resource_converter_by_type("Cardinal",	0, cvt_from_Int);

    register_resource_converter_by_type("Display",	"X::Display", 0);
    register_resource_converter_by_type("Screen",	"X::Screen", 0);
    register_resource_converter_by_type("Window",	"X::Window", 0);
    register_resource_converter_by_type("Pixmap",	"X::Pixmap", 0);
    register_resource_converter_by_type("Font",		"X::Font", 0);
    register_resource_converter_by_type("Pixel",	"X::Pixel", 0);
    register_resource_converter_by_type("Colormap",	"X::Colormap", 0);
    register_resource_converter_by_type("Visual",	"X::Visual", 0);

    register_resource_converter_by_type("Widget",	"X::Toolkit::Widget", 0);
    register_resource_converter_by_type("WidgetClass",  "X::Toolkit::WidgetClass", 0);
