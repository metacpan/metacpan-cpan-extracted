
#include <stdio.h>
#include <stdlib.h>

#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>

#include <Xm/XmP.h>
#include <Xm/PrimitiveP.h>
#include <Xm/ManagerP.h>
#include <X11/ConstrainP.h>

#include "XpStackP.h"
#include "XpFolder.h"

#define Offset(field) XtOffsetOf(XpStackRec, xpStack.field)

static XtResource resources[] =
{
    { XtNoutsideMargin, XtCOutsideMargin, XtRDimension, sizeof(Dimension),
      Offset(outside_margin), XtRImmediate, (XtPointer)4},

    { XtNnowDisplayedCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
      Offset(now_displayed_cb), XtRImmediate, 0 },

    { XtNnowHiddenCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
      Offset(now_hidden_cb), XtRImmediate, 0 }
};

#undef Offset

#define Offset(field) XtOffsetOf(XpStackConstraintRec, xpStack.field)

static XtResource constraint_resources[] =
{
    { XtNlayerName, XtCLayerName, XtRString, sizeof(String),
      Offset(layer_name), XtRString, 0 },

    { XtNlayerActive, XtCLayerActive, XtRBoolean, sizeof(Boolean),
      Offset(layer_active), XtRImmediate, (XtPointer)True }
};

#undef Offset

extern WidgetClass xpStackWidgetClass;

#define DEFAULT_WIDTH	100
#define DEFAULT_HEIGHT	100

static void internal_StackSetActiveChild(XpStackWidget self, int i)
{
    if (i < 0) i = 0;
    if (i >= self->composite.num_children) i = self->composite.num_children - 1;

    if (i != -1)
    {
	int save_i = i;

	while (i < self->composite.num_children && !XtIsManaged(self->composite.children[i])) ++i;

	if (i >= self->composite.num_children)
	{
	    i = save_i;
	    while (i >= 0 && !XtIsManaged(self->composite.children[i])) --i;
	}
    }

    self->xpStack.last_active_child = self->xpStack.active_child;
    self->xpStack.active_child = i;
}

static int internal_StackGetActiveChild(XpStackWidget self)
{
    return(self->xpStack.active_child);
}

static void Initialize(Widget req_widget, Widget new_widget, ArgList args, Cardinal *num_args)
{
    XpStackWidget self = (XpStackWidget)new_widget;

    if (self->core.width <= 0) self->core.width = DEFAULT_WIDTH;
    if (self->core.height <= 0) self->core.height = DEFAULT_HEIGHT;

    self->xpStack.active_child = -1;
    self->xpStack.last_active_child = -1;
}

static int internal_StackChildWidgetOrder(XpStackWidget self, Widget child)
{
    if (self)
    {
	int i;

	for (i = 0; i < self->composite.num_children; ++i)
	{
	    if (child == self->composite.children[i]) return(i);
	}
    }

    return(-1);
}

static void InsertChild(Widget w)
{
    XpStackWidget self = (XpStackWidget)XtParent(w);
    CompositeWidgetClass parent_class = (CompositeWidgetClass)xpStackWidgetClass->core_class.superclass;

    w->core.border_width = 0;
    w->core.mapped_when_managed = False;

    parent_class->composite_class.insert_child(w);

    if (internal_StackGetActiveChild(self) == -1)
    {
	internal_StackSetActiveChild(self, internal_StackChildWidgetOrder(self, w));
    }
}

static void DisplayActiveChild(XpStackWidget self)
{
    Widget child, folder;

    if (XtIsRealized(self) && self->xpStack.last_active_child != self->xpStack.active_child)
    {
	if (self->xpStack.last_active_child >= 0)
	{
	    child = self->composite.children[self->xpStack.last_active_child];

	    XtCallCallbackList((Widget)self, self->xpStack.now_hidden_cb, child);
	}

	if (self->xpStack.active_child >= 0)
	{
	    child = self->composite.children[self->xpStack.active_child];

	    if (XtIsManaged(child) && XtWindow(child) != 0)
	    {
		XtMapWidget(child);
		XRaiseWindow(XtDisplay(child), XtWindow(child));

		XmProcessTraversal(child, XmTRAVERSE_CURRENT);
	    }

	    /* Notify the parent folder widget of the new active child so that
	       it can properly update the tab display.  (This could use the
	       callback system and avoid close coupling to the folder class!)  Use
	       the same technique for the change managed notify as well.  FIXME */

	    folder = XtParent(self);
	    if (folder && XtClass(folder) == xpFolderWidgetClass) XpFolderRedisplayTabsNotify(folder);

	    /* Run the user-defined callbacks so that they can take advantage of
	       stopping/starting animations and other time consuming operations that
	       are only useful when the widget is displayed. */

	    XtCallCallbackList((Widget)self, self->xpStack.now_displayed_cb, child);
	}
    }
}

static void DeleteChild(Widget w)
{
    XpStackWidget self = (XpStackWidget)XtParent(w);
    CompositeWidgetClass parent_class = (CompositeWidgetClass)xpStackWidgetClass->core_class.superclass;
    int i = internal_StackChildWidgetOrder(self, w);

    parent_class->composite_class.delete_child(w);

    /* The widget being deleted can never be the active child because
       deleted widgets are always unmanaged before being deleted.  The
       ChangeManaged() method ensures that unmanaged active widgets lose
       their active status. */

    if (i <= internal_StackGetActiveChild(self))
    {
	internal_StackSetActiveChild(self, internal_StackGetActiveChild(self) - 1);
    }
}

static void Resize(Widget w)
{
    XpStackWidget self = (XpStackWidget)w;
    Position margin_space = self->xpStack.outside_margin + self->core.border_width;
    Dimension width = self->core.width - margin_space * 2;
    Dimension height = self->core.height - margin_space * 2;
    int i;

    if (width <= 0) width = 1;
    if (height <= 0) height = 1;

    for (i = 0; i < self->composite.num_children; i++)
    {
	XtConfigureWidget(self->composite.children[i], margin_space, margin_space, width, height, 0);
    }
}

static void Realize(Widget w, XtValueMask *value_mask, XSetWindowAttributes *attributes)
{
    XpStackWidget self = (XpStackWidget)w;

    xpStackWidgetClass->core_class.superclass->core_class.realize(w, value_mask, attributes);

    if (self->xpStack.active_child >= 0)
    {
	Widget child = self->composite.children[self->xpStack.active_child];

	/* Realize the active child by hand so that the nowDisplayed callback
	   can be easily run.  If the widget was not realized, then a window
	   would not yet exist and the user might have to do some special
	   programming.  Because this Xt is not expecting this manual realize,
	   the auto-mapping of managed widgets is turned off.  This will
	   prevent Xt from mapping any other child widgets (which would be stacked
	   on top of the active widget.) */

	XtRealizeWidget(child);
	XtMapWidget(child);

	XtCallCallbackList((Widget)self, self->xpStack.now_displayed_cb, child);
    }
}

static XtGeometryResult handle_layout(XpStackWidget self, Widget requesting_child,
				      XtWidgetGeometry *desired, XtWidgetGeometry *allowed)
{
    XtWidgetGeometry desired_by_me;
    XtWidgetGeometry desired_by_child;
    XtWidgetGeometry allowed_by_parent;
    Dimension saved_width, saved_height;
    int margin_space;
    int i, r;

#define Wants(flag)	    (desired->request_mode & (flag))
#define RestoreGeometry()   do { self->core.width = saved_width; self->core.height = saved_height; } while (0)

    if (Wants(CWX | CWY | CWSibling | CWStackMode | CWBorderWidth)) return(XtGeometryNo);

    saved_width = self->core.width;
    saved_height = self->core.height;

    margin_space = self->xpStack.outside_margin * 2 + self->core.border_width * 2;

    desired_by_me.width = (Wants(CWWidth)) ? desired->width : self->core.width - margin_space;
    desired_by_me.height = (Wants(CWHeight)) ? desired->height : self->core.height - margin_space;

    for (i = 0; i < self->composite.num_children; ++i)
    {
	Widget child = self->composite.children[i];

	if (child != requesting_child && XtIsManaged(child))
	{
	    XtQueryGeometry(child, 0, &desired_by_child);

	    if (desired_by_child.width > desired_by_me.width) desired_by_me.width = desired_by_child.width;
	    if (desired_by_child.height > desired_by_me.height) desired_by_me.height = desired_by_child.height;
	}
    }

    desired_by_me.width += margin_space;
    desired_by_me.height += margin_space;

    if (desired_by_me.width <= 0) desired_by_me.width = saved_width;
    if (desired_by_me.height <= 0) desired_by_me.height = saved_height;

    if (desired_by_me.width == saved_width && desired_by_me.height == saved_height) return(XtGeometryDone);

    desired_by_me.request_mode = CWWidth | CWHeight;
    if (Wants(XtCWQueryOnly)) desired_by_me.request_mode |= XtCWQueryOnly;

    while ((r = XtMakeGeometryRequest((Widget)self, &desired_by_me,
				      &allowed_by_parent)) == XtGeometryAlmost)
    {
	desired_by_me = allowed_by_parent;
    }

    if (r == XtGeometryNo)
    {
	RestoreGeometry();
	return(XtGeometryNo);
    }

    desired_by_me.width -= margin_space;
    desired_by_me.height -= margin_space;

    if ((!Wants(CWWidth) || desired_by_me.width == desired->width || 0 == desired->width) &&
	(!Wants(CWHeight) || desired_by_me.height == desired->height || 0 == desired->height))
    {
	if (Wants(XtCWQueryOnly))
	{
	    RestoreGeometry();
	    return(XtGeometryYes);
	}
	else
	{
	    Resize((Widget)self);
	    return(XtGeometryDone);
	}
    }

    RestoreGeometry();

    allowed->width = desired_by_me.width;
    allowed->height = desired_by_me.height;
    allowed->request_mode = CWWidth | CWHeight;

    return(XtGeometryAlmost);

#undef Wants
#undef RestoreGeometry

}

static XtGeometryResult GeometryManager(Widget requesting_child,
					XtWidgetGeometry *desired, XtWidgetGeometry *allowed)
{
    return(handle_layout((XpStackWidget)XtParent(requesting_child), requesting_child, desired, allowed));
}

static void ChangeManaged(Widget w)
{
    XpStackWidget self = (XpStackWidget)w;
    XtWidgetGeometry desired_by_me;
    XtWidgetGeometry allowed_by_parent;
    Widget folder;

    desired_by_me.request_mode = CWWidth | CWHeight;
    desired_by_me.width = 0;
    desired_by_me.height = 0;

    handle_layout(self, 0, &desired_by_me, &allowed_by_parent);

    /* Try to set the old active widget as the new active widget.  This
       runs the consistency checks to make sure that the widget still
       exists and is managed.  Since we know the managed set has changed,
       which means that a widget has been mapped or unmapped, we always call
       the display routine to make sure the active window is on the top
       of the stacking order.  Auto-mapping of widgets is explicitly turned
       off so that the stacking order is not disturbed. */

    internal_StackSetActiveChild(self, internal_StackGetActiveChild(self));

    /* Notify the parent folder widget of the newly managed/unmanaged children
       so that it can properly compute where the tabs should be displayed. */

    folder = XtParent(self);
    if (folder && XtClass(folder) == xpFolderWidgetClass) XpFolderTabsChangedNotify(folder);

    DisplayActiveChild(self);
}

static XpStackWidget XpStackWidgetCast(Widget w)
{
    WidgetClass widget_class = w->core.widget_class;

    while (widget_class != 0 && widget_class != coreWidgetClass)
    {
	if (widget_class == xpStackWidgetClass)
	{
	    return((XpStackWidget)w);
	}
	if (widget_class == xpFolderWidgetClass)
	{
	    XtVaGetValues(w, XtNstackWidget, &w, 0);
	    return((XpStackWidget)w);
	}
	widget_class = widget_class->core_class.superclass;
    }

    return(0);
}

int XpStackNumChildren(Widget w)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	return(self->composite.num_children);
    }

    return(-1);
}

int XpStackChildWidgetOrder(Widget w)
{
    XpStackWidget self = XpStackWidgetCast(XtParent(w));

    return(internal_StackChildWidgetOrder(self, w));
}

void XpStackNextWidget(Widget w)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	internal_StackSetActiveChild(self, internal_StackGetActiveChild(self) + 1);
	DisplayActiveChild(self);
    }
}

void XpStackPreviousWidget(Widget w)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	internal_StackSetActiveChild(self, internal_StackGetActiveChild(self) - 1);
	DisplayActiveChild(self);
    }
}

void XpStackGotoWidget(Widget w, int i)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	if (i < 0) i = self->composite.num_children + i;
	internal_StackSetActiveChild(self, i);
	DisplayActiveChild(self);
    }
}

void XpStackSetActiveChild(Widget w, int i)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	internal_StackSetActiveChild(self, i);
    }
}

int XpStackGetActiveChild(Widget w)
{
    XpStackWidget self = XpStackWidgetCast(w);

    if (self)
    {
	return(internal_StackGetActiveChild(self));
    }

    return(-1);
}

XpStackClassRec xpStackClassRec = 
{
    /* Core class part */

    {
	/* superclass               */ (WidgetClass)&xmManagerClassRec,
	/* class_name               */ "XpStack",
	/* widget_size              */ sizeof(XpStackRec),
	/* class_initialize         */ 0,
	/* class_part_initialize    */ 0,
	/* class_inited             */ False,
	/* initialize               */ Initialize,
	/* initialize_hook          */ 0,
	/* realize                  */ Realize,
	/* actions                  */ 0,
	/* num_actions              */ 0,
	/* resources                */ resources,
	/* num_resources            */ XtNumber(resources),
	/* xrm_class                */ NULLQUARK,
	/* compress_motion          */ True,
	/* compress_exposure        */ XtExposeCompressMultiple,
	/* compress_enterleave      */ True,
	/* visible_interest         */ False,
	/* destroy                  */ 0,
	/* resize                   */ Resize,
	/* expose                   */ 0,
	/* set_values               */ 0,
	/* set_values_hook          */ 0,
	/* set_values_almost        */ XtInheritSetValuesAlmost,
	/* get_values_hook          */ 0,
	/* accept_focus             */ XtInheritAcceptFocus,
	/* version                  */ XtVersion,
	/* callback offsets         */ 0,
	/* tm_table                 */ XtInheritTranslations,
	/* query_geometry           */ XtInheritQueryGeometry,
	/* display_accelerator      */ XtInheritDisplayAccelerator,
	/* extension                */ 0
    },

    /* Composite Part */

    {
	/* geometry_manager         */ GeometryManager,
	/* change_managed           */ ChangeManaged,
	/* insert_child             */ InsertChild,
	/* delete_child             */ DeleteChild,
	/* extension                */ 0
    },

    /* Constraint Part */

    {
	/* resources                */ constraint_resources,
	/* num_resources            */ XtNumber(constraint_resources),
	/* constraint_size          */ sizeof(XpStackConstraintRec), 
	/* initialize               */ 0,
	/* destroy                  */ 0,
	/* set_values               */ 0,
	/* extension                */ 0
    },

    /* Manager Part */

    {
	XtInheritTranslations,
	0,
	0,
	0,
	0,
	XmInheritParentProcess,
	0
    },

    /* XpStack class part */

    {
	/* example so I remember...  */ 0
    }
};

WidgetClass xpStackWidgetClass = (WidgetClass)&xpStackClassRec;
