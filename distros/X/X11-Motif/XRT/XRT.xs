
/* Copyright 1998 by Ken Fox */

#include "motif-api.h"

#ifdef WANT_XRT_GRAPH
#include <Xm/XrtGraph.h>
#endif

#ifdef WANT_XRT_GEAR
#include <Xm/XrtGear.h>
#include <Xm/XrtGearString.h>
#include <Xm/XrtOutliner.h>
#include <Xm/XrtNode.h>
#include <Xm/XrtNodeFolder.h>
#include <Xm/XrtNodeStyle.h>
#include <Xm/XrtColumn.h>
#include <Xm/XrtToggleB.h>
#endif

char *XrtTextHandle_Package = "X::XRT::TextHandle";
char *XrtDataHandle_Package = "X::XRT::DataHandle";

char *XrtAnyCallbackStructPtr_Package = "X::XRT::AnyCallData";
char *XrtAnyGearCallbackStructPtr_Package = "X::XRT::AnyGearCallData";
char *XrtGenericContainerCallbackStructPtr_Package = "X::XRT::GenericContainerCallData";
char *XrtGearNodeFolderStateCallbackStructPtr_Package = "X::XRT::FolderStateCallData";
char *XrtGearSelectCallbackStructPtr_Package = "X::XRT::SelectCallData";
char *XrtGearNodeActivateCallbackStructPtr_Package = "X::XRT::NodeActivateCallData";

char *Xrt_perl_GearString_Package = "X::XRT::perl_GearString";
char *Xrt_perl_GearList_Package = "X::XRT::perl_GearList";
char *Xrt_perl_DataStyle_Package = "X::XRT::perl_DataStyle";
char *Xrt_perl_DataStyles_Package = "X::XRT::perl_DataStyles";
char *Xrt_perl_Strings_Package = "X::XRT::perl_Strings";
char *Xrt_perl_Float_Package = "X::XRT::perl_Float";

typedef struct {
    int reason;
} XrtAnyCallbackStruct;

typedef struct {
    int reason;
    XEvent *event;
} XrtAnyGearCallbackStruct;

typedef struct {
    int reason;
    XEvent *event;
    Widget container;
    Widget node;
} XrtGenericContainerCallbackStruct;

#ifdef WANT_XRT_GRAPH
typedef XrtDataStyle *Xrt_perl_DataStyle;
typedef XrtDataStyle **Xrt_perl_DataStyles;
#endif

#ifdef WANT_XRT_GEAR
typedef XrtGearObject Xrt_perl_GearString;
typedef XrtGearObject Xrt_perl_GearList;
#endif

typedef char **Xrt_perl_Strings;
typedef XtArgVal Xrt_perl_Float;

static void free_xrt_array(void **self)
{
    void **element = self;

    while (*element != 0) {
	free(*element);
	++element;
    }

    free(self);
}

#ifdef WANT_XRT_GRAPH

Xrt_perl_DataStyle convert_to_DataStyle(SV *array_in)
{
    Xrt_perl_DataStyle RETVAL = 0;
    int line_color_len = 0;
    int point_color_len = 0;

    if (SvROK(array_in) && SvTYPE(SvRV(array_in)) == SVt_PVAV) {
	if ((RETVAL = malloc(sizeof(XrtDataStyle) + line_color_len + point_color_len + 2)) != 0) {
	    /* copy struct values into struct */
	}
    }

    return RETVAL;
}

Xrt_perl_DataStyles convert_to_DataStyles(SV *array_in)
{
    Xrt_perl_DataStyles RETVAL = 0;
    AV *av;
    SV **sv;
    int i;
    int len;

    if (SvROK(array_in) && SvTYPE(SvRV(array_in)) == SVt_PVAV) {
	av = (AV *)SvRV(array_in);
	len = AvFILL(av) + 1;
    }
    else {
	croak("array_in is not an array reference");
    }

    if ((RETVAL = malloc((len + 1) * sizeof(char *))) == 0) {
	croak("not enough memory for 'DataStyles' resource conversion");
    }

    for (i = 0; i < len; ++i) {
	sv = av_fetch(av, i, 0);
	RETVAL[i] = (sv) ? convert_to_DataStyle(*sv) : 0;
    }

    RETVAL[len] = 0;

    return RETVAL;
}

#endif

Xrt_perl_Strings convert_to_Strings(SV *array_in)
{
    Xrt_perl_Strings RETVAL = 0;
    AV *av = 0;
    STRLEN element_len;
    char *element;
    int len;

    if (SvROK(array_in) && SvTYPE(SvRV(array_in)) == SVt_PVAV) {
	av = (AV *)SvRV(array_in);
	len = AvFILL(av) + 1;
    }
    else if (SvPOK(array_in)) {
	len = 1;
    }
    else {
	croak("array_in is not an array reference");
    }

    if ((RETVAL = malloc((len + 1) * sizeof(char *))) == 0) {
	croak("not enough memory for 'Strings' resource conversion");
    }

    if (av) {
	int i = 0;
	SV **sv;

	while (i < len)
	{
	    sv = av_fetch(av, i, 0);
	    if (sv && SvPOK(*sv) && (element = SvPV(*sv, element_len)) != 0) {
		if ((RETVAL[i] = malloc(element_len + 1)) != 0)
		    strcpy(RETVAL[i], element);
	    }
	    else {
		RETVAL[i] = 0;
	    }
	    ++i;
	}
    }
    else {
	if ((element = SvPV(array_in, element_len)) != 0) {
	    if ((*RETVAL = malloc(element_len + 1)) != 0)
		strcpy(*RETVAL, element);
	}
	else {
	    *RETVAL = 0;
	}
    }

    RETVAL[len] = 0;

    return RETVAL;
}

#ifdef WANT_XRT_GEAR

static SV *cvt_from_XrtObject(Widget w, WidgetClass wc, XtOutArg in)
{
    XrtGearObject r = (XrtGearObject)in->dst;

    /* Should a copy of this XrtObject be made?  when should the XrtObject
       be released?  Is it ok to just let perl garbage collect it whenever? */

    if (XrtGearListIsList(r)) {
	int len = XrtGearListGetItemCount(r);
	AV *array = newAV();
	int i = 0;

	av_extend(array, len);
	while (i < len) {
	    av_store(array, i, sv_setref_pv(newSViv(0), Widget_Package,
					    *(Widget *)XrtGearListGetItem(r, i)));
	    ++i;
	}

	return sv_2mortal(newRV_inc((SV *)array));
    }
    else {
	return sv_setref_pv(sv_newmortal(), "X::Toolkit::Opaque", (void *)r);
    }
}

#endif


MODULE = X11::XRT	PACKAGE = X::XRT

PROTOTYPES: ENABLE

#ifdef WANT_XRT_GRAPH

WidgetClass
xtXrtGraphWidgetClass()
	CODE:
	    RETVAL = xtXrtGraphWidgetClass;
	OUTPUT:
	    RETVAL

XrtDataHandle
XrtDataCreateFromFile(filename, error = 0)
	char *		filename
	char *		error

Xrt_perl_DataStyle
convert_to_DataStyle(array_in)
	SV *		array_in

Xrt_perl_DataStyles
convert_to_DataStyles(array_in)
	SV *		array_in

#endif

#ifdef WANT_XRT_GEAR

WidgetClass
xmXrtOutlinerWidgetClass()
	CODE:
	    RETVAL = xmXrtOutlinerWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmXrtNodeFolderObjectClass()
	CODE:
	    RETVAL = xmXrtNodeFolderObjectClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmXrtNodeObjectClass()
	CODE:
	    RETVAL = xmXrtNodeObjectClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmXrtNodeStyleObjectClass()
	CODE:
	    RETVAL = xmXrtNodeStyleObjectClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmXrtColumnObjectClass()
	CODE:
	    RETVAL = xmXrtColumnObjectClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmXrtToggleButtonWidgetClass()
	CODE:
	    RETVAL = xmXrtToggleButtonWidgetClass;
	OUTPUT:
	    RETVAL

int
XmIsXrtNode(w)
	Widget		w

int
XmIsXrtNodeFolder(w)
	Widget		w

Widget
XrtGearNodeGetWidgetParent(w)
	Widget		w

Xrt_perl_GearString
XrtGearStringCreateCharString(str)
	char *		str

Xrt_perl_GearString
XrtGearStringCreateXmString(str)
	XmString	str

#endif

Xrt_perl_Strings
convert_to_Strings(array_in)
	SV *		array_in

Xrt_perl_Float
convert_to_Float(value)
	double		value
	CODE:
	    RETVAL = XrtFloatToArgVal(value);
	OUTPUT:
	    RETVAL


MODULE = X11::XRT	PACKAGE = X::XRT::AnyCallData

int
reason(self)
	XrtAnyCallbackStruct *		self
	CODE:
	    RETVAL = self->reason;
	OUTPUT:
	    RETVAL


MODULE = X11::XRT	PACKAGE = X::XRT::AnyGearCallData

#ifdef WANT_XRT_GEAR

void
event(self)
	XrtAnyGearCallbackStruct *	self
	PPCODE:
	    if (self->event != 0) {
		XPUSHs(sv_setref_pv(sv_newmortal(), XEventPtr_Package(self->event->type), (void *)self->event));
	    }


MODULE = X11::XRT	PACKAGE = X::XRT::GenericContainerCallData

Widget
container(self)
	XrtGenericContainerCallbackStruct *		self
	CODE:
	    RETVAL = self->container;
	OUTPUT:
	    RETVAL

Widget
node(self)
	XrtGenericContainerCallbackStruct *		self
	CODE:
	    RETVAL = self->node;
	OUTPUT:
	    RETVAL


MODULE = X11::XRT	PACKAGE = X::XRT::FolderStateCallData

int
new_state(self)
	XrtGearNodeFolderStateCallbackStruct *		self
	CODE:
	    RETVAL = self->new_state;
	OUTPUT:
	    RETVAL

int
old_state(self)
	XrtGearNodeFolderStateCallbackStruct *		self
	CODE:
	    RETVAL = self->old_state;
	OUTPUT:
	    RETVAL

void
doit(self, ...)
	XrtGearNodeFolderStateCallbackStruct *		self
	PPCODE:
	    if (items == 2) {
		self->doit = SvTRUE(ST(1));
	    }
	    else {
		XPUSHs(sv_2mortal(newSViv(self->doit)));
	    }


MODULE = X11::XRT	PACKAGE = X::XRT::SelectCallData

void
selected_node_list(self)
	XrtGearSelectCallbackStruct *			self
	PPCODE:
	    if (XrtGearListIsList(self->selected_node_list)) {
		int len = XrtGearListGetItemCount(self->selected_node_list);
		int i = 0;
		printf(" *** list with %d items\n", len);
		EXTEND(sp, len);
		while (i < len) {
		    PUSHs(sv_setref_pv(sv_newmortal(), Widget_Package,
				       *(Widget *)XrtGearListGetItem(self->selected_node_list, i)));
		    ++i;
		}
	    }
	    else {
		printf(" *** single element\n");
		PUSHs(sv_setref_pv(sv_newmortal(), Widget_Package, self->selected_node_list));
	    }

void
doit(self, ...)
	XrtGearSelectCallbackStruct *			self
	PPCODE:
	    if (items == 2) {
		self->doit = SvTRUE(ST(1));
	    }
	    else {
		XPUSHs(sv_2mortal(newSViv(self->doit)));
	    }



MODULE = X11::XRT	PACKAGE = X::XRT::NodeActivateCallData

int
click_count(self)
	XrtGearNodeActivateCallbackStruct *		self
	CODE:
	    RETVAL = self->click_count;
	OUTPUT:
	    RETVAL


#endif

#ifdef XRT_WANT_GRAPH

MODULE = X11::XRT	PACKAGE = X::XRT::perl_DataStyle

void
DESTROY(self)
	Xrt_perl_DataStyle	self
	CODE:
	    if (self) {
		free(self);
	    }


MODULE = X11::XRT	PACKAGE = X::XRT::perl_DataStyles

void
DESTROY(self)
	Xrt_perl_DataStyles	self
	CODE:
	    if (self) {
		free_xrt_array((void **)self);
	    }

#endif

#ifdef WANT_XRT_GEAR

MODULE = X11::XRT	PACKAGE = X::XRT::perl_GearString

void
DESTROY(self)
	Xrt_perl_GearString	self
	CODE:
	    /* hard to believe that XRT doesn't require these XtArgVals
	       to be destroyed.  is this an XRT bug? */


MODULE = X11::XRT	PACKAGE = X::XRT::perl_GearList

void
DESTROY(self)
	Xrt_perl_GearList	self
	CODE:
	    /* hard to believe that XRT doesn't require these XtArgVals
	       to be destroyed.  is this an XRT bug? */

#endif

MODULE = X11::XRT	PACKAGE = X::XRT::perl_Strings

void
DESTROY(self)
	Xrt_perl_Strings	self
	CODE:
	    if (self) {
		free_xrt_array((void **)self);
	    }


MODULE = X11::XRT	PACKAGE = X::XRT::perl_Float

void
DESTROY(self)
	Xrt_perl_Float		self
	CODE:
	    /* hard to believe that XRT doesn't require these XtArgVals
	       to be destroyed.  is this an XRT bug? */


BOOT:

    /* initialize XRT type converters for C to Perl */
    register_resource_converter_by_type("GearNodeChildList",	0, cvt_from_XrtObject);
