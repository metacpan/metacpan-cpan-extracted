
/* Copyright 1997 by Ken Fox */

#include "motif-api.h"

#ifdef WANT_XBAE

typedef struct _XbaeAnyCallbackStruct
{
    XbaeReasonType reason;
}
XbaeAnyCallbackStruct;

typedef struct _XbaeRowColumnCallbackStruct
{
    XbaeReasonType reason;
    int row, column;
}
XbaeRowColumnCallbackStruct;

char *XbaeAnyCallbackStructPtr_Package = "X::bae::AnyCallData";
char *XbaeRowColumnCallbackStructPtr_Package = "X::bae::RowColumnCallData";
char *XbaeMatrixDefaultActionCallbackStructPtr_Package = "X::bae::MatrixDefaultActionCallData";
char *XbaeMatrixEnterCellCallbackStructPtr_Package = "X::bae::MatrixEnterCellCallData";
char *XbaeMatrixLeaveCellCallbackStructPtr_Package = "X::bae::MatrixLeaveCellCallData";

#endif

char *XmString_Package = "X::Motif::String";
char *XmAnyCallbackStructPtr_Package = "X::Motif::AnyCallData";
char *XmArrowButtonCallbackStructPtr_Package = "X::Motif::ArrowButtonCallData";
char *XmDrawingAreaCallbackStructPtr_Package = "X::Motif::DrawingAreaCallData";
char *XmDrawnButtonCallbackStructPtr_Package = "X::Motif::DrawnButtonCallData";
char *XmPushButtonCallbackStructPtr_Package = "X::Motif::PushButtonCallData";
char *XmRowColumnCallbackStructPtr_Package = "X::Motif::RowColumnCallData";
char *XmScrollBarCallbackStructPtr_Package = "X::Motif::ScrollBarCallData";
char *XmToggleButtonCallbackStructPtr_Package = "X::Motif::ToggleButtonCallData";
char *XmListCallbackStructPtr_Package = "X::Motif::ListCallData";
char *XmSelectionBoxCallbackStructPtr_Package = "X::Motif::SelectionBoxCallData";
char *XmCommandCallbackStructPtr_Package = "X::Motif::CommandCallData";
char *XmFileSelectionBoxCallbackStructPtr_Package = "X::Motif::FileSelectionBoxCallData";
char *XmScaleCallbackStructPtr_Package = "X::Motif::ScaleCallData";
char *XmTextVerifyCallbackStructPtr_Package = "X::Motif::TextVerifyCallData";
char *XmTraverseObscuredCallbackStructPtr_Package = "X::Motif::TraverseObscuredCallData";

char *wchar_tPtr_Package = "X::Motif::WideChar";

char *XmFontContext_Package = "X::Motif::FontContext";
char *XmFontList_Package = "X::Motif::FontList";
char *XmFontListEntry_Package = "X::Motif::FontListEntry";
char *XmFontType_Package = "X::Motif::FontType";
char *XmStringCharSet_Package = "X::Motif::StringCharSet";
char *XmTextSource_Package = "X::Motif::TextSource";
char *XmStringContext_Package = "X::Motif::StringContext";


static SV *cvt_from_XmString(Widget w, WidgetClass wc, XtOutArg in)
{
    XmString r = (XmString)in->dst;

    /* Should a copy of this XmString be made?  when should the XmString
       be released?  Is it ok to just let perl garbage collect it whenever? */

    return sv_setref_pv(sv_newmortal(), "X::Motif::String", r);
}

static SV *cvt_from_UserData(Widget w, WidgetClass wc, XtOutArg in)
{
    void *r = (void *)in->dst;

    /* This is a fast and dangerous implementation of Perl UserData.  It
       assumes that any resource value that isn't a small integer is a
       pointer to an SV.  If C code that uses UserData is mixed with Perl
       code that uses UserData there could be fireworks.  The solution to
       this is to keep all Perl UserData in an array.  Then the resource
       value can be validated -- it might still be wrong, but at least
       it wouldn't crash.  The severe down side to that approach is that
       UserData becomes quite expensive to keep track of.

       The above approach was modified slightly to take advantage of the
       fact that SV pointers will be evenly aligned.  (Is there any
       architecture that supports Motif that this isn't true for?)  If
       an odd pointer is found, it is treated as a boxed unsigned integer. */

    if (r) {
	unsigned int v = (unsigned int)r;

	if (v & 1) {
	    /* A "boxed" value was stored instead of an SV.  This is the
	       fastest and most efficient way of storing user data, but only
	       positive integers less than PERL_INT_MAX can be stored. */

	    return sv_2mortal(newSViv((int)(v >> 1)));
	}
	else if (v < 200) {
	    /* Somebody is using C code with Perl -- a warning might
	       be appropriate here because this will almost always indicate
	       a bug. */

	    return sv_2mortal(newSViv((int)v));
	}
	else {
	    /* Assume that any other value is an SV *.  If this module is
	       not used with any external C code then this is a safe assumption.
	       If widgets are created with external C code and the user data
	       is set from that code then there is a good chance that this will
	       crash the application.  The bottom line is to be very careful
	       when mixing Perl code and C code.

	       The returned value is not mortalized because the widget maintains
	       its copy.  It would probably be better to increment the reference
	       count and mortalize the value.  This would protect against the
	       possibility that the widget gets destroyed while the return value
	       is still on the stack. */

	    return r;
	}
    }

    return &sv_undef;
}


/* A much better job could be done in placing functions in the appropriate
   packages.  The only trouble lies in exporting symbols to the global
   name space -- it is a little bit slower when symbols are scattered
   around.  FIXME */

MODULE = X11::Motif	PACKAGE = X::Motif

PROTOTYPES: ENABLE

WidgetClass
overrideShellWidgetClass()
	CODE:
	    RETVAL = overrideShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
transientShellWidgetClass()
	CODE:
	    RETVAL = transientShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
topLevelShellWidgetClass()
	CODE:
	    RETVAL = topLevelShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
applicationShellWidgetClass()
	CODE:
	    RETVAL = applicationShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
wmShellWidgetClass()
	CODE:
	    RETVAL = wmShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
vendorShellWidgetClass()
	CODE:
	    RETVAL = vendorShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmArrowButtonWidgetClass()
	CODE:
	    RETVAL = xmArrowButtonWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmLabelWidgetClass()
	CODE:
	    RETVAL = xmLabelWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmCascadeButtonWidgetClass()
	CODE:
	    RETVAL = xmCascadeButtonWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmDrawnButtonWidgetClass()
	CODE:
	    RETVAL = xmDrawnButtonWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmPushButtonWidgetClass()
	CODE:
	    RETVAL = xmPushButtonWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmToggleButtonWidgetClass()
	CODE:
	    RETVAL = xmToggleButtonWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmListWidgetClass()
	CODE:
	    RETVAL = xmListWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmScrollBarWidgetClass()
	CODE:
	    RETVAL = xmScrollBarWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmSeparatorWidgetClass()
	CODE:
	    RETVAL = xmSeparatorWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmTextWidgetClass()
	CODE:
	    RETVAL = xmTextWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmTextFieldWidgetClass()
	CODE:
	    RETVAL = xmTextFieldWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmBulletinBoardWidgetClass()
	CODE:
	    RETVAL = xmBulletinBoardWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmFormWidgetClass()
	CODE:
	    RETVAL = xmFormWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmSelectionBoxWidgetClass()
	CODE:
	    RETVAL = xmSelectionBoxWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmCommandWidgetClass()
	CODE:
	    RETVAL = xmCommandWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmFileSelectionBoxWidgetClass()
	CODE:
	    RETVAL = xmFileSelectionBoxWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmMessageBoxWidgetClass()
	CODE:
	    RETVAL = xmMessageBoxWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmDrawingAreaWidgetClass()
	CODE:
	    RETVAL = xmDrawingAreaWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmFrameWidgetClass()
	CODE:
	    RETVAL = xmFrameWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmPanedWindowWidgetClass()
	CODE:
	    RETVAL = xmPanedWindowWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmRowColumnWidgetClass()
	CODE:
	    RETVAL = xmRowColumnWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmScaleWidgetClass()
	CODE:
	    RETVAL = xmScaleWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmScrolledWindowWidgetClass()
	CODE:
	    RETVAL = xmScrolledWindowWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmMainWindowWidgetClass()
	CODE:
	    RETVAL = xmMainWindowWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmDialogShellWidgetClass()
	CODE:
	    RETVAL = xmDialogShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xmMenuShellWidgetClass()
	CODE:
	    RETVAL = xmMenuShellWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xpFolderWidgetClass()
	CODE:
	    RETVAL = xpFolderWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xpStackWidgetClass()
	CODE:
	    RETVAL = xpStackWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xpLinedAreaWidgetClass()
	CODE:
	    RETVAL = xpLinedAreaWidgetClass;
	OUTPUT:
	    RETVAL

void
XmIsPrimitive(self)
	Widget		self
	PPCODE:
	    if (XmIsPrimitive(self)) { XPUSHs(&sv_yes); } else { XPUSHs(&sv_no); }

void
XmIsManager(self)
	Widget		self
	PPCODE:
	    if (XmIsManager(self)) { XPUSHs(&sv_yes); } else { XPUSHs(&sv_no); }



MODULE = X11::Motif	PACKAGE = X::Toolkit::Widget

void
XpLinedAreaInsertOutlineColumn(w, col, width, object_ref, event_proc = 0)
	Widget		w
	int		col
	int		width
	SV *		object_ref
	SV *		event_proc
	PPCODE:
	    if (object_ref && SvROK(object_ref) && sv_derived_from(object_ref, "Outline")) {
		/* memory leak of event_proc and object_ref - FIXME */

		if (event_proc) {
		    event_proc = SvREFCNT_inc(event_proc);
		}

		XpLinedAreaInsertColumn(w, col, SvREFCNT_inc(object_ref),
					XpLinedAreaWidth, width,
					XpLinedAreaDivideVertical, 0,
					XpLinedAreaCallEvent, xp_outliner_event_handler, event_proc,
					XpLinedAreaCallExpose, xp_outliner_expose_handler, 0,
					0);
	    }

void
XpLinedAreaRedraw(w)
	Widget		w

void
XpLinedAreaRedrawColumn(w, col, should_display)
	Widget		w
	int		col
	int		should_display

void
XpLinedAreaRedrawCell(w, row, col)
	Widget		w
	int		row
	int		col

void
XpLinedAreaSetRows(w, col, rows)
	Widget		w
	int		col
	int		rows
	PPCODE:
	    XpLinedAreaChangeColumn(w, col, XpLinedAreaRows, rows, XpLinedAreaEnd);

void
XpLinedAreaGetRows(w)
	Widget		w

void
XpLinedAreaScrollToRow(w, row)
	Widget		w
	int		row



MODULE = X11::Motif	PACKAGE = X::Motif

int
XmListYToPos(w, y)
	Widget		w
	Position	y

# ----------------------------------------------------------------------
# The next section was derived from an automatically generated XS
# template.

# -- BEGIN list-raw-funs OUTPUT --
void
XmAddTabGroup(tabGroup)
	Widget			tabGroup

void
XmAddToPostFromList(menu_wid, widget)
	Widget			menu_wid
	Widget			widget

void
XmCascadeButtonHighlight(cb, highlight)
	Widget			cb
	int			highlight

void
XmChangeColor(widget, background)
	Widget			widget
	Pixel			background

void
XmCommandAppendValue(widget, value)
	Widget			widget
	XmString		value

void
XmCommandError(widget, error)
	Widget			widget
	XmString		error

Widget
XmCommandGetChild(widget, child)
	Widget			widget
	unsigned int		child

void
XmCommandSetValue(widget, value)
	Widget			widget
	XmString		value

int
XmConvertUnits(widget, dimension, from_type, from_val, to_type)
	Widget			widget
	int			dimension
	int			from_type
	int			from_val
	int			to_type

Widget
priv_XmCreateArrowButton(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateArrowButton(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateBulletinBoard(p, name, ...)
	Widget			p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateBulletinBoard(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateBulletinBoardDialog(ds_p, name, ...)
	Widget			ds_p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(ds_p, XtClass(ds_p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateBulletinBoardDialog(ds_p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateCascadeButton(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateCascadeButton(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateCommand(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateCommand(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateCommandDialog(ds_p, name, ...)
	Widget			ds_p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(ds_p, XtClass(ds_p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateCommandDialog(ds_p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateDialogShell(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateDialogShell(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateDrawingArea(p, name, ...)
	Widget			p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateDrawingArea(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateDrawnButton(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateDrawnButton(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateErrorDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateErrorDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateFileSelectionBox(p, name, ...)
	Widget			p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateFileSelectionBox(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateFileSelectionDialog(ds_p, name, ...)
	Widget			ds_p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(ds_p, XtClass(ds_p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateFileSelectionDialog(ds_p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateForm(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateForm(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateFormDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateFormDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateFrame(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateFrame(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateInformationDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateInformationDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateLabel(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateLabel(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateList(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateList(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateMainWindow(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateMainWindow(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateMenuBar(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateMenuBar(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateMenuShell(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateMenuShell(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateMessageBox(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateMessageBox(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateMessageDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateMessageDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateOptionMenu(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateOptionMenu(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreatePanedWindow(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreatePanedWindow(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreatePopupMenu(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreatePopupMenu(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreatePromptDialog(ds_p, name, ...)
	Widget			ds_p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(ds_p, XtClass(ds_p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreatePromptDialog(ds_p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreatePulldownMenu(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreatePulldownMenu(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreatePushButton(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreatePushButton(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateQuestionDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateQuestionDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateRadioBox(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateRadioBox(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateRowColumn(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateRowColumn(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateScale(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateScale(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateScrollBar(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateScrollBar(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateScrolledList(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateScrolledList(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateScrolledText(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateScrolledText(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateScrolledWindow(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateScrolledWindow(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSelectionBox(p, name, ...)
	Widget			p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSelectionBox(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSelectionDialog(ds_p, name, ...)
	Widget			ds_p
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(ds_p, XtClass(ds_p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSelectionDialog(ds_p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSeparator(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSeparator(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimpleCheckBox(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimpleCheckBox(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimpleMenuBar(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimpleMenuBar(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimpleOptionMenu(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimpleOptionMenu(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimplePopupMenu(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimplePopupMenu(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimplePulldownMenu(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimplePulldownMenu(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateSimpleRadioBox(parent, name, ...)
	Widget			parent
	String			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateSimpleRadioBox(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateTemplateDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateTemplateDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateText(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateText(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateTextField(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateTextField(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateToggleButton(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateToggleButton(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateWarningDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateWarningDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateWorkArea(p, name, ...)
	Widget			p
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(p, XtClass(p), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateWorkArea(p, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Widget
priv_XmCreateWorkingDialog(parent, name, ...)
	Widget			parent
	char *			name
	PREINIT:
	    ArgList arg_list = 0;
	    Cardinal arg_list_len = 0;
	CODE:
	    arg_list_len = xt_build_input_arg_list(parent, XtClass(parent), &arg_list, &ST(2), items - 2);
	    RETVAL = XmCreateWorkingDialog(parent, name, arg_list, arg_list_len);
	    if (arg_list) free(arg_list);
	OUTPUT:
	    RETVAL

Boolean
XmDestroyPixmap(screen, pixmap)
	Screen *		screen
	Pixmap			pixmap

Widget
XmFileSelectionBoxGetChild(fs, which)
	Widget			fs
	unsigned int		which

void
XmFileSelectionDoSearch(fs, dirmask)
	Widget			fs
	XmString		dirmask

XmFontList
XmFontListAdd(old, font, charset)
	XmFontList		old
	XFontStruct *		font
	XmStringCharSet		charset

XmFontList
XmFontListAppendEntry(old, entry)
	XmFontList		old
	XmFontListEntry		entry

XmFontList
XmFontListCopy(fontlist)
	XmFontList		fontlist

XmFontList
XmFontListCreate(font, charset)
	XFontStruct *		font
	XmStringCharSet		charset

XmFontListEntry
XmFontListEntryCreate(tag, type, font)
	char *			tag
	XmFontType		type
	XtPointer		font

void
XmFontListEntryFree(entry)
	XmFontListEntry *	entry

XtPointer
XmFontListEntryGetFont(entry, typeReturn)
	XmFontListEntry		entry
	XmFontType *		typeReturn

char *
XmFontListEntryGetTag(entry)
	XmFontListEntry		entry

XmFontListEntry
XmFontListEntryLoad(display, fontName, type, tag)
	Display *		display
	char *			fontName
	XmFontType		type
	char *			tag

void
XmFontListFree(fontlist)
	XmFontList		fontlist

void
XmFontListFreeFontContext(context)
	XmFontContext		context

Boolean
XmFontListGetNextFont(context, charset, font)
	XmFontContext		context
	XmStringCharSet *	charset
	XFontStruct **		font

Boolean
XmFontListInitFontContext(context, fontlist)
	XmFontContext *		context
	XmFontList		fontlist

XmFontListEntry
XmFontListNextEntry(context)
	XmFontContext		context

XmFontList
XmFontListRemoveEntry(old, entry)
	XmFontList		old
	XmFontListEntry		entry

void
XmGetColors(screen, color_map, background, foreground_ret, top_shadow_ret, bottom_shadow_ret, select_ret)
	Screen *		screen
	Colormap		color_map
	Pixel			background
	Pixel *			foreground_ret
	Pixel *			top_shadow_ret
	Pixel *			bottom_shadow_ret
	Pixel *			select_ret

Widget
XmGetDestination(display)
	Display *		display

Widget
XmGetFocusWidget(wid)
	Widget			wid

Cursor
XmGetMenuCursor(display)
	Display *		display

Pixmap
XmGetPixmap(screen, image_name, foreground, background)
	Screen *		screen
	char *			image_name
	Pixel			foreground
	Pixel			background

Pixmap
XmGetPixmapByDepth(screen, image_name, foreground, background, depth)
	Screen *		screen
	char *			image_name
	Pixel			foreground
	Pixel			background
	int			depth

Widget
XmGetPostedFromWidget(menu)
	Widget			menu

Cardinal
XmGetSecondaryResourceData(w_class, secondaryDataRtn)
	WidgetClass		w_class
	XmSecondaryResourceData **	secondaryDataRtn

Widget
XmGetTabGroup(wid)
	Widget			wid

Widget
XmGetTearOffControl(menu)
	Widget			menu

XmVisibility
XmGetVisibility(wid)
	Widget			wid

Widget
XmGetXmScreen(screen)
	Screen *		screen

Boolean
XmInstallImage(image, image_name)
	XImage *		image
	char *			image_name

Boolean
XmIsMotifWMRunning(shell)
	Widget			shell

Boolean
XmIsTraversable(wid)
	Widget			wid

void
XmListAddItem(w, item, pos)
	Widget			w
	XmString		item
	int			pos

void
XmListAddItemUnselected(w, item, pos)
	Widget			w
	XmString		item
	int			pos

void
XmListAddItems(w, items, item_count, pos)
	Widget			w
	XmString *		items
	int			item_count
	int			pos

void
XmListAddItemsUnselected(w, items, item_count, pos)
	Widget			w
	XmString *		items
	int			item_count
	int			pos

void
XmListDeleteAllItems(w)
	Widget			w

void
XmListDeleteItem(w, item)
	Widget			w
	XmString		item

void
XmListDeleteItems(w, items, item_count)
	Widget			w
	XmString *		items
	int			item_count

void
XmListDeleteItemsPos(w, item_count, pos)
	Widget			w
	int			item_count
	int			pos

void
XmListDeletePos(w, pos)
	Widget			w
	int			pos

void
XmListDeletePositions(w, position_list, position_count)
	Widget			w
	int *			position_list
	int			position_count

void
XmListDeselectAllItems(w)
	Widget			w

void
XmListDeselectItem(w, item)
	Widget			w
	XmString		item

void
XmListDeselectPos(w, pos)
	Widget			w
	int			pos

int
XmListGetKbdItemPos(w)
	Widget			w

Boolean
XmListGetMatchPos(w, item, pos_list, pos_count)
	Widget			w
	XmString		item
	int **			pos_list
	int *			pos_count

Boolean
XmListGetSelectedPos(w, pos_list, pos_count)
	Widget			w
	int **			pos_list
	int *			pos_count

Boolean
XmListItemExists(w, item)
	Widget			w
	XmString		item

int
XmListItemPos(w, item)
	Widget			w
	XmString		item

Boolean
XmListPosSelected(w, pos)
	Widget			w
	int			pos

Boolean
XmListPosToBounds(w, position, x, y, width, height)
	Widget			w
	int			position
	Position *		x
	Position *		y
	Dimension *		width
	Dimension *		height

void
XmListReplaceItems(w, old_items, item_count, new_items)
	Widget			w
	XmString *		old_items
	int			item_count
	XmString *		new_items

void
XmListReplaceItemsPos(w, new_items, item_count, position)
	Widget			w
	XmString *		new_items
	int			item_count
	int			position

void
XmListReplaceItemsPosUnselected(w, new_items, item_count, position)
	Widget			w
	XmString *		new_items
	int			item_count
	int			position

void
XmListReplaceItemsUnselected(w, old_items, item_count, new_items)
	Widget			w
	XmString *		old_items
	int			item_count
	XmString *		new_items

void
XmListReplacePositions(w, position_list, item_list, item_count)
	Widget			w
	int *			position_list
	XmString *		item_list
	int			item_count

void
XmListSelectItem(w, item, notify)
	Widget			w
	XmString		item
	int			notify

void
XmListSelectPos(w, pos, notify)
	Widget			w
	int			pos
	int			notify

void
XmListSetAddMode(w, add_mode)
	Widget			w
	int			add_mode

void
XmListSetBottomItem(w, item)
	Widget			w
	XmString		item

void
XmListSetBottomPos(w, pos)
	Widget			w
	int			pos

void
XmListSetHorizPos(w, position)
	Widget			w
	int			position

void
XmListSetItem(w, item)
	Widget			w
	XmString		item

Boolean
XmListSetKbdItemPos(w, pos)
	Widget			w
	int			pos

void
XmListSetPos(w, pos)
	Widget			w
	int			pos

void
XmListUpdateSelectedList(w)
	Widget			w

Widget
XmMainWindowSep1(w)
	Widget			w

Widget
XmMainWindowSep2(w)
	Widget			w

Widget
XmMainWindowSep3(w)
	Widget			w

void
XmMainWindowSetAreas(w, menu, command, hscroll, vscroll, wregion)
	Widget			w
	Widget			menu
	Widget			command
	Widget			hscroll
	Widget			vscroll
	Widget			wregion

char *
XmMapSegmentEncoding(fontlist_tag)
	char *			fontlist_tag

void
XmMenuPosition(p, event)
	Widget			p
	XButtonPressedEvent *	event

Widget
XmMessageBoxGetChild(widget, child)
	Widget			widget
	unsigned int		child

Widget
XmOptionButtonGadget(m)
	Widget			m

Widget
XmOptionLabelGadget(m)
	Widget			m

Boolean
XmProcessTraversal(w, dir)
	Widget			w
	XmTraversalDirection	dir

char *
XmRegisterSegmentEncoding(fontlist_tag, ct_encoding)
	char *			fontlist_tag
	char *			ct_encoding

void
XmRemoveFromPostFromList(menu_wid, widget)
	Widget			menu_wid
	Widget			widget

void
XmRemoveTabGroup(w)
	Widget			w

void
XmResolveAllPartOffsets(w_class, offset, constraint_offset)
	WidgetClass		w_class
	XmOffsetPtr *		offset
	XmOffsetPtr *		constraint_offset

void
XmResolvePartOffsets(w_class, offset)
	WidgetClass		w_class
	XmOffsetPtr *		offset

void
XmScaleGetValue(w, value)
	Widget			w
	int *			value

void
XmScaleSetValue(w, value)
	Widget			w
	int			value

void
XmScrollBarGetValues(w, value, slider_size, increment, page_increment)
	Widget			w
	int *			value
	int *			slider_size
	int *			increment
	int *			page_increment

void
XmScrollBarSetValues(w, value, slider_size, increment, page_increment, notify)
	Widget			w
	int			value
	int			slider_size
	int			increment
	int			page_increment
	int			notify

void
XmScrollVisible(scrw, wid, hor_margin, ver_margin)
	Widget			scrw
	Widget			wid
	Dimension		hor_margin
	Dimension		ver_margin

void
XmScrolledWindowSetAreas(w, hscroll, vscroll, wregion)
	Widget			w
	Widget			hscroll
	Widget			vscroll
	Widget			wregion

Widget
XmSelectionBoxGetChild(sb, which)
	Widget			sb
	unsigned int		which

XmColorProc
XmSetColorCalculation(proc)
	XmColorProc		proc

void
XmSetFontUnit(display, value)
	Display *		display
	int			value

void
XmSetFontUnits(display, h_value, v_value)
	Display *		display
	int			h_value
	int			v_value

void
XmSetMenuCursor(display, cursorId)
	Display *		display
	Cursor			cursorId

Dimension
XmStringBaseline(fontlist, string)
	XmFontList		fontlist
	XmString		string

Boolean
XmStringByteCompare(a1, b1)
	XmString		a1
	XmString		b1

Boolean
XmStringCompare(a, b)
	XmString		a
	XmString		b

XmString
XmStringConcat(a, b)
	XmString		a
	XmString		b

XmString
XmStringCopy(string)
	XmString		string

XmString
XmStringCreate(text, charset)
	char *			text
	XmStringCharSet		charset

XmFontList
XmStringCreateFontList(font, charset)
	XFontStruct *		font
	XmStringCharSet		charset

XmString
XmStringCreateLocalized(text)
	String			text

XmString
XmStringCreateLtoR(text, charset)
	char *			text
	XmStringCharSet		charset

XmString
XmStringCreateSimple(text)
	char *			text

XmString
XmStringDirectionCreate(direction)
	int			direction

void
XmStringDraw(d, w, fontlist, string, gc, x, y, width, align, lay_dir, clip)
	Display *		d
	Window			w
	XmFontList		fontlist
	XmString		string
	GC			gc
	int			x
	int			y
	int			width
	unsigned int		align
	unsigned int		lay_dir
	XRectangle *		clip

void
XmStringDrawImage(d, w, fontlist, string, gc, x, y, width, align, lay_dir, clip)
	Display *		d
	Window			w
	XmFontList		fontlist
	XmString		string
	GC			gc
	int			x
	int			y
	int			width
	unsigned int		align
	unsigned int		lay_dir
	XRectangle *		clip

void
XmStringDrawUnderline(d, w, fntlst, str, gc, x, y, width, align, lay_dir, clip, under)
	Display *		d
	Window			w
	XmFontList		fntlst
	XmString		str
	GC			gc
	int			x
	int			y
	int			width
	unsigned int		align
	unsigned int		lay_dir
	XRectangle *		clip
	XmString		under

Boolean
XmStringEmpty(string)
	XmString		string

void
XmStringExtent(fontlist, string, width, height)
	XmFontList		fontlist
	XmString		string
	Dimension *		width
	Dimension *		height

void
XmStringFree(string)
	XmString		string

void
XmStringFreeContext(context)
	XmStringContext		context

Boolean
XmStringGetLtoR(string, charset, text)
	XmString		string
	XmStringCharSet		charset
	char **			text

XmStringComponentType
XmStringGetNextComponent(context, text, charset, direction, unknown_tag, unknown_length, unknown_value)
	XmStringContext		context
	char **			text
	XmStringCharSet *	charset
	XmStringDirection *	direction
	XmStringComponentType *	unknown_tag
	unsigned short *	unknown_length
	unsigned char **	unknown_value

Boolean
XmStringGetNextSegment(context, text, charset, direction, separator)
	XmStringContext		context
	char **			text
	XmStringCharSet *	charset
	XmStringDirection *	direction
	Boolean *		separator

Boolean
XmStringHasSubstring(string, substring)
	XmString		string
	XmString		substring

Dimension
XmStringHeight(fontlist, string)
	XmFontList		fontlist
	XmString		string

Boolean
XmStringInitContext(context, string)
	XmStringContext *	context
	XmString		string

int
XmStringLength(string)
	XmString		string

int
XmStringLineCount(string)
	XmString		string

XmString
XmStringLtoRCreate(text, charset)
	char *			text
	XmStringCharSet		charset

XmString
XmStringNConcat(first, second, n)
	XmString		first
	XmString		second
	int			n

XmString
XmStringNCopy(str, n)
	XmString		str
	int			n

XmStringComponentType
XmStringPeekNextComponent(context)
	XmStringContext		context

XmString
XmStringSegmentCreate(text, charset, direction, separator)
	char *			text
	XmStringCharSet		charset
	int			direction
	int			separator

Dimension
XmStringWidth(fontlist, string)
	XmFontList		fontlist
	XmString		string

void
XmTextClearSelection(widget, clear_time)
	Widget			widget
	Time			clear_time

Boolean
XmTextCopy(widget, copy_time)
	Widget			widget
	Time			copy_time

Boolean
XmTextCut(widget, cut_time)
	Widget			widget
	Time			cut_time

void
XmTextDisableRedisplay(widget)
	Widget			widget

void
XmTextEnableRedisplay(widget)
	Widget			widget

void
XmTextFieldClearSelection(w, sel_time)
	Widget			w
	Time			sel_time

Boolean
XmTextFieldCopy(w, clip_time)
	Widget			w
	Time			clip_time

Boolean
XmTextFieldCut(w, clip_time)
	Widget			w
	Time			clip_time

Boolean
XmTextFieldGetAddMode(w)
	Widget			w

int
XmTextFieldGetBaseline(w)
	Widget			w

XmTextPosition
XmTextFieldGetCursorPosition(w)
	Widget			w

Boolean
XmTextFieldGetEditable(w)
	Widget			w

XmTextPosition
XmTextFieldGetInsertionPosition(w)
	Widget			w

XmTextPosition
XmTextFieldGetLastPosition(w)
	Widget			w

int
XmTextFieldGetMaxLength(w)
	Widget			w

char *
XmTextFieldGetSelection(w)
	Widget			w

Boolean
XmTextFieldGetSelectionPosition(w, left, right)
	Widget			w
	XmTextPosition *	left
	XmTextPosition *	right

wchar_t *
XmTextFieldGetSelectionWcs(w)
	Widget			w

char *
XmTextFieldGetString(w)
	Widget			w

wchar_t *
XmTextFieldGetStringWcs(w)
	Widget			w

int
XmTextFieldGetSubstring(widget, start, num_chars, buf_size, buffer)
	Widget			widget
	XmTextPosition		start
	int			num_chars
	int			buf_size
	char *			buffer

int
XmTextFieldGetSubstringWcs(widget, start, num_chars, buf_size, buffer)
	Widget			widget
	XmTextPosition		start
	int			num_chars
	int			buf_size
	wchar_t *		buffer

void
XmTextFieldInsert(w, position, value)
	Widget			w
	XmTextPosition		position
	char *			value

void
XmTextFieldInsertWcs(w, position, wcstring)
	Widget			w
	XmTextPosition		position
	wchar_t *		wcstring

Boolean
XmTextFieldPaste(w)
	Widget			w

Boolean
XmTextFieldPosToXY(w, position, x, y)
	Widget			w
	XmTextPosition		position
	Position *		x
	Position *		y

Boolean
XmTextFieldRemove(w)
	Widget			w

void
XmTextFieldReplace(w, from_pos, to_pos, value)
	Widget			w
	XmTextPosition		from_pos
	XmTextPosition		to_pos
	char *			value

void
XmTextFieldReplaceWcs(w, from_pos, to_pos, wc_value)
	Widget			w
	XmTextPosition		from_pos
	XmTextPosition		to_pos
	wchar_t *		wc_value

void
XmTextFieldSetAddMode(w, state)
	Widget			w
	int			state

void
XmTextFieldSetCursorPosition(w, position)
	Widget			w
	XmTextPosition		position

void
XmTextFieldSetEditable(w, editable)
	Widget			w
	int			editable

void
XmTextFieldSetHighlight(w, left, right, mode)
	Widget			w
	XmTextPosition		left
	XmTextPosition		right
	XmHighlightMode		mode

void
XmTextFieldSetInsertionPosition(w, position)
	Widget			w
	XmTextPosition		position

void
XmTextFieldSetMaxLength(w, max_length)
	Widget			w
	int			max_length

void
XmTextFieldSetSelection(w, first, last, sel_time)
	Widget			w
	XmTextPosition		first
	XmTextPosition		last
	Time			sel_time

void
XmTextFieldSetString(w, value)
	Widget			w
	char *			value

void
XmTextFieldSetStringWcs(w, wc_value)
	Widget			w
	wchar_t *		wc_value

void
XmTextFieldShowPosition(w, position)
	Widget			w
	XmTextPosition		position

XmTextPosition
XmTextFieldXYToPos(w, x, y)
	Widget			w
	int			x
	int			y

Boolean
XmTextFindString(w, start, search_string, direction, position)
	Widget			w
	XmTextPosition		start
	char *			search_string
	XmTextDirection		direction
	XmTextPosition *	position

Boolean
XmTextFindStringWcs(w, start, wc_string, direction, position)
	Widget			w
	XmTextPosition		start
	wchar_t *		wc_string
	XmTextDirection		direction
	XmTextPosition *	position

Boolean
XmTextGetAddMode(widget)
	Widget			widget

int
XmTextGetBaseline(widget)
	Widget			widget

XmTextPosition
XmTextGetCursorPosition(widget)
	Widget			widget

Boolean
XmTextGetEditable(widget)
	Widget			widget

XmTextPosition
XmTextGetInsertionPosition(widget)
	Widget			widget

XmTextPosition
XmTextGetLastPosition(widget)
	Widget			widget

int
XmTextGetMaxLength(widget)
	Widget			widget

char *
XmTextGetSelection(widget)
	Widget			widget

Boolean
XmTextGetSelectionPosition(widget, left, right)
	Widget			widget
	XmTextPosition *	left
	XmTextPosition *	right

wchar_t *
XmTextGetSelectionWcs(widget)
	Widget			widget

XmTextSource
XmTextGetSource(widget)
	Widget			widget

char *
XmTextGetString(widget)
	Widget			widget

wchar_t *
XmTextGetStringWcs(widget)
	Widget			widget

int
XmTextGetSubstring(widget, start, num_chars, buf_size, buffer)
	Widget			widget
	XmTextPosition		start
	int			num_chars
	int			buf_size
	char *			buffer

int
XmTextGetSubstringWcs(widget, start, num_chars, buf_size, buffer)
	Widget			widget
	XmTextPosition		start
	int			num_chars
	int			buf_size
	wchar_t *		buffer

XmTextPosition
XmTextGetTopCharacter(widget)
	Widget			widget

void
XmTextInsert(widget, position, value)
	Widget			widget
	XmTextPosition		position
	char *			value

void
XmTextInsertWcs(widget, position, wc_value)
	Widget			widget
	XmTextPosition		position
	wchar_t *		wc_value

Boolean
XmTextPaste(widget)
	Widget			widget

Boolean
XmTextPosToXY(widget, position, x, y)
	Widget			widget
	XmTextPosition		position
	Position *		x
	Position *		y

Boolean
XmTextRemove(widget)
	Widget			widget

void
XmTextReplace(widget, frompos, topos, value)
	Widget			widget
	XmTextPosition		frompos
	XmTextPosition		topos
	char *			value

void
XmTextReplaceWcs(widget, frompos, topos, value)
	Widget			widget
	XmTextPosition		frompos
	XmTextPosition		topos
	wchar_t *		value

void
XmTextScroll(widget, n)
	Widget			widget
	int			n

void
XmTextSetAddMode(widget, state)
	Widget			widget
	int			state

void
XmTextSetCursorPosition(widget, position)
	Widget			widget
	XmTextPosition		position

void
XmTextSetEditable(widget, editable)
	Widget			widget
	int			editable

void
XmTextSetHighlight(w, left, right, mode)
	Widget			w
	XmTextPosition		left
	XmTextPosition		right
	XmHighlightMode		mode

void
XmTextSetInsertionPosition(widget, position)
	Widget			widget
	XmTextPosition		position

void
XmTextSetMaxLength(widget, max_length)
	Widget			widget
	int			max_length

void
XmTextSetSelection(widget, first, last, set_time)
	Widget			widget
	XmTextPosition		first
	XmTextPosition		last
	Time			set_time

void
XmTextSetSource(widget, source, top_character, cursor_position)
	Widget			widget
	XmTextSource		source
	XmTextPosition		top_character
	XmTextPosition		cursor_position

void
XmTextSetString(widget, value)
	Widget			widget
	char *			value

void
XmTextSetStringWcs(widget, wc_value)
	Widget			widget
	wchar_t *		wc_value

void
XmTextSetTopCharacter(widget, top_character)
	Widget			widget
	XmTextPosition		top_character

void
XmTextShowPosition(widget, position)
	Widget			widget
	XmTextPosition		position

XmTextPosition
XmTextXYToPos(widget, x, y)
	Widget			widget
	int			x
	int			y

Boolean
XmToggleButtonGetState(w)
	Widget			w

void
XmToggleButtonSetState(w, newstate, notify)
	Widget			w
	int			newstate
	int			notify

Widget
XmTrackingEvent(widget, cursor, confineTo, pev)
	Widget			widget
	Cursor			cursor
	int			confineTo
	XEvent *		pev

Widget
XmTrackingLocate(widget, cursor, confineTo)
	Widget			widget
	Cursor			cursor
	int			confineTo

void
XmTranslateKey(dpy, keycode, modifiers, modifiers_return, keysym_return)
	Display *		dpy
	unsigned int		keycode
	Modifiers		modifiers
	Modifiers *		modifiers_return
	KeySym *		keysym_return

Boolean
XmUninstallImage(image)
	XImage *		image

void
XmUpdateDisplay(w)
	Widget			w

Boolean
XmWidgetGetBaselines(wid, baselines, line_count)
	Widget			wid
	Dimension **		baselines
	int *			line_count

Boolean
XmWidgetGetDisplayRect(wid, displayrect)
	Widget			wid
	XRectangle *		displayrect

# -- END list-raw-funs OUTPUT --




MODULE = X11::Motif	PACKAGE = X::Motif::AnyCallData

int
reason(self)
	XmAnyCallbackStruct *		self
	CODE:
	    RETVAL = self->reason;
	OUTPUT:
	    RETVAL

void
event(self)
	XmAnyCallbackStruct *		self
	PPCODE:
	    if (self->event != 0) {
		XPUSHs(sv_setref_pv(sv_newmortal(), XEventPtr_Package(self->event->type), (void *)self->event));
	    }

MODULE = X11::Motif	PACKAGE = X::Motif::ArrowButtonCallData

MODULE = X11::Motif	PACKAGE = X::Motif::DrawingAreaCallData

MODULE = X11::Motif	PACKAGE = X::Motif::DrawnButtonCallData

MODULE = X11::Motif	PACKAGE = X::Motif::PushButtonCallData

MODULE = X11::Motif	PACKAGE = X::Motif::RowColumnCallData

MODULE = X11::Motif	PACKAGE = X::Motif::ScrollBarCallData

MODULE = X11::Motif	PACKAGE = X::Motif::ToggleButtonCallData

MODULE = X11::Motif	PACKAGE = X::Motif::ListCallData

void
item(self)
	XmListCallbackStruct *		self
	PREINIT:
	    SV *sv;
	PPCODE:
	    if (self->reason == XmCR_MULTIPLE_SELECT ||
		self->reason == XmCR_EXTENDED_SELECT)
	    {
		if (self->selected_item_count > 0)
		{
		    sv = sv_newmortal();
		    sv_setref_pv(sv, "X::Motif::String", XmStringCopy(self->selected_items[0]));
		    PUSHs(sv);
		}
	    }
	    else if (self->selected_item_count > 0)
	    {
		sv = sv_newmortal();
		sv_setref_pv(sv, "X::Motif::String", XmStringCopy(self->item));
		PUSHs(sv);
	    }

int
item_length(self)
	XmListCallbackStruct *		self
	CODE:
	    RETVAL = self->item_length;
	OUTPUT:
	    RETVAL

int
item_position(self)
	XmListCallbackStruct *		self
	CODE:
	    RETVAL = self->item_position;
	OUTPUT:
	    RETVAL

int
selected_item_count(self)
	XmListCallbackStruct *		self
	CODE:
	    if (self->reason == XmCR_MULTIPLE_SELECT ||
		self->reason == XmCR_EXTENDED_SELECT)
	    {
		RETVAL = self->selected_item_count;
	    }
	    else
	    {
		RETVAL = 1;
	    }
	OUTPUT:
	    RETVAL

void
selected_items(self)
	XmListCallbackStruct *		self
	PREINIT:
	    int i;
	    SV *sv;
	PPCODE:
	    if (self->reason == XmCR_MULTIPLE_SELECT ||
		self->reason == XmCR_EXTENDED_SELECT)
	    {
		EXTEND(sp, self->selected_item_count);
		for (i = 0; i < self->selected_item_count; ++i)
		{
		    sv = sv_newmortal();
		    sv_setref_pv(sv, "X::Motif::String", XmStringCopy(self->selected_items[i]));
		    PUSHs(sv);
		}
	    }
	    else
	    {
		sv = sv_newmortal();
		sv_setref_pv(sv, "X::Motif::String", XmStringCopy(self->item));
		PUSHs(sv);
	    }

MODULE = X11::Motif	PACKAGE = X::Motif::SelectionBoxCallData

MODULE = X11::Motif	PACKAGE = X::Motif::CommandCallData

MODULE = X11::Motif	PACKAGE = X::Motif::FileSelectionCallData

MODULE = X11::Motif	PACKAGE = X::Motif::ScaleCallData

MODULE = X11::Motif	PACKAGE = X::Motif::TextVerifyCallData

void
text(self)
	XmTextVerifyCallbackStruct *	self
	PREINIT:
	    SV *sv;
	PPCODE:
	    if (self->reason == XmCR_MODIFYING_TEXT_VALUE ||
		self->reason == XmCR_MOVING_INSERT_CURSOR)
	    {
		if (self->text && self->text->ptr) {
		    sv = sv_newmortal();
		    sv_setpvn(sv, self->text->ptr, self->text->length);
		    PUSHs(sv);
		}
	    }

void
deny_change(self)
	XmTextVerifyCallbackStruct *	self
	CODE:
	    if (self->reason == XmCR_MODIFYING_TEXT_VALUE ||
		self->reason == XmCR_MOVING_INSERT_CURSOR)
	    {
		self->doit = 0;
	    }

MODULE = X11::Motif	PACKAGE = X::Motif::TraverseObscuredCallData




MODULE = X11::Motif	PACKAGE = X::Motif::String

XmString
new(class_name, text)
	char *		class_name
	char *		text
	CODE:
	    RETVAL = XmStringCreateLtoR(text, XmSTRING_DEFAULT_CHARSET);
	OUTPUT:
	    RETVAL

void
DESTROY(self)
	XmString	self
	PPCODE:
	    if (self) {
		XmStringFree(self);
	    }

char *
plain(self)
	XmString	self
	CODE:
	    if (self) XmStringGetLtoR(self, XmSTRING_DEFAULT_CHARSET, &RETVAL);
	OUTPUT:
	    RETVAL



MODULE = X11::Motif	PACKAGE = X::bae

#ifdef WANT_XBAE

WidgetClass
xbaeMatrixWidgetClass()
	CODE:
	    RETVAL = xbaeMatrixWidgetClass;
	OUTPUT:
	    RETVAL

WidgetClass
xbaeCaptionWidgetClass()
	CODE:
	    RETVAL = xbaeCaptionWidgetClass;
	OUTPUT:
	    RETVAL

void
XbaeMatrixRefresh(widget)
	Widget					widget

void
XbaeMatrixRefreshCell(widget, row, column)
	Widget					widget
	int					row
	int					column

void
XbaeMatrixSetCell(widget, row, column, value)
	Widget					widget
	int					row
	int					column
	char *					value


MODULE = X11::Motif	PACKAGE = X::bae::AnyCallData

int
reason(self)
	XbaeAnyCallbackStruct *			self
	CODE:
	    RETVAL = self->reason;
	OUTPUT:
	    RETVAL

MODULE = X11::Motif	PACKAGE = X::bae::RowColumnCallData

int
row(self)
	XbaeRowColumnCallbackStruct *		self
	CODE:
	    RETVAL = self->row;
	OUTPUT:
	    RETVAL

int
column(self)
	XbaeRowColumnCallbackStruct *		self
	CODE:
	    RETVAL = self->column;
	OUTPUT:
	    RETVAL

MODULE = X11::Motif	PACKAGE = X::bae::MatrixDefaultActionCallData

MODULE = X11::Motif	PACKAGE = X::bae::MatrixEnterCellCallData

int
select_text(self, set = -1)
	XbaeMatrixEnterCellCallbackStruct *	self
	int					set
	CODE:
	    if (set > -1) {
		self->select_text = set;
	    }
	    RETVAL = self->select_text;
	OUTPUT:
	    RETVAL

int
map(self, set = -1)
	XbaeMatrixEnterCellCallbackStruct *	self
	int					set
	CODE:
	    if (set > -1) {
		self->map = set;
	    }
	    RETVAL = self->map;
	OUTPUT:
	    RETVAL

int
doit(self, set = -1)
	XbaeMatrixEnterCellCallbackStruct *	self
	int					set
	CODE:
	    if (set > -1) {
		self->doit = set;
	    }
	    RETVAL = self->doit;
	OUTPUT:
	    RETVAL

MODULE = X11::Motif	PACKAGE = X::bae::MatrixLeaveCellCallData

char *
value(self, set = 0)
	XbaeMatrixLeaveCellCallbackStruct *	self
	char *					set
	CODE:
	    if (set != 0) {
		if (self->value && strlen(self->value) >= strlen(set)) {
		    strcpy(self->value, set);
		}
		else {
		    self->value = XtNewString(set);
		}
	    }
	    RETVAL = self->value;
	OUTPUT:
	    RETVAL

int
doit(self, set = -1)
	XbaeMatrixLeaveCellCallbackStruct *	self
	int					set
	CODE:
	    if (set > -1) {
		self->doit = set;
	    }
	    RETVAL = self->doit;
	OUTPUT:
	    RETVAL

#endif


BOOT:
    register_resource_converter_by_type("XmString",	0, cvt_from_XmString);
    register_resource_converter_by_class("UserData",	0, cvt_from_UserData);
    /* when linking statically the Toolkit's bootstrap statement is
       inserted into the perl main(). */
#ifndef HAVE_TOOLKIT_BOOT
    newXSproto("X11::Toolkit::bootstrap", boot_X11__Toolkit, file, "");
#endif
