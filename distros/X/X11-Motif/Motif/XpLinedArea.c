
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#include <X11/Xatom.h>
#include <X11/keysym.h>

#include <Xm/Xm.h>
#include <Xm/XmP.h>
#include <Xm/PrimitiveP.h>
#include <Xm/ScrollBar.h>
#include <Xm/ScrolledW.h>

#include "XpLinedAreaP.h"

#define DEFAULT_CELL_HEIGHT	    10
#define DEFAULT_CELL_WIDTH	    150
#define DEFAULT_ROW_COUNT	    100
#define DEFAULT_VISIBLE_ROW_COUNT   5

#define Offset(field)	XtOffsetOf(XpLinedAreaRec, xpLinedArea.field)

static XtResource resources[] =
{
    { XtNspace, XtCSpace, XtRDimension, sizeof(Dimension),
      Offset(space), XtRImmediate, (XtPointer)2 },

    { XtNrows, XtCRows, XtRInt, sizeof(int),
      Offset(rows), XtRImmediate, (XtPointer)DEFAULT_ROW_COUNT },

    { XtNvisibleRows, XtCVisibleRows, XtRInt, sizeof(int),
      Offset(visibleRows), XtRImmediate, (XtPointer)DEFAULT_VISIBLE_ROW_COUNT },

    { XtNcellHeight, XtCCellHeight, XtRDimension, sizeof(Dimension),
      Offset(cellHeight), XtRImmediate, (XtPointer)0 },

    { XtNmaxDisplayWidth, XtCMaxDisplayWidth, XtRDimension, sizeof(Dimension),
      Offset(maxDisplayWidth), XtRImmediate, (XtPointer)800 },

    { XtNborderWidth, XtCBorderWidth, XtRDimension, sizeof(Dimension),
      XtOffsetOf(XpLinedAreaRec, core.border_width), XtRImmediate, (XtPointer)0 },

    { XtNforeground, XtCForeground, XtRPixel, sizeof(Pixel),
      Offset(foreground), XtRString, "XtDefaultForeground" },

    { XtNfont, XtCFont, XtRFontStruct, sizeof(XFontStruct *),
      Offset(font), XtRString, "XtDefaultFont" },

    { XtNcolorAltRows, XtCColorAltRows, XtRInt, sizeof(int),
      Offset(colorAltRows), XtRImmediate, (XtPointer)0 },

    { XtNfirstColoredRow, XtCFirstColoredRow, XtRInt, sizeof(int),
      Offset(firstColoredRow), XtRImmediate, (XtPointer)0 },

    { XtNaltBackground, XtCAltBackground, XtRPixel, sizeof(Pixel),
      Offset(altBackground), XtRString, "XtDefaultBackground" },

    { XtNindentationIncr, XtCIndentationIncr, XtRInt, sizeof(int),
      Offset(indentationIncr), XtRImmediate, (XtPointer)0 },

    { XtNinternalPadding, XtCInternalPadding, XtRInt, sizeof(int),
      Offset(internalPadding), XtRImmediate, (XtPointer)0 },
};

#undef Offset

extern WidgetClass xpLinedAreaWidgetClass;

#define GET_ROW_FROM_COORD(Y) (self->xpLinedArea.topRow + (Y) / self->xpLinedArea.cellHeight)

int XpGetRowFromCoord(Widget w, int y)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    int row = GET_ROW_FROM_COORD(y);

    if (row > self->xpLinedArea.rows) {
	row = self->xpLinedArea.rows - 1;
    }

    return row;
}

XpLinedAreaColumn *XpGetCellFromCoord(Widget w, int x, int y, int *row_out, int *col_out)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;
    int col, row;

    x += self->xpLinedArea.leftMargin;

    for (col = 0; col < self->xpLinedArea.num_columns; ++col) {
	this_col = self->xpLinedArea.column[col];

	if (x < this_col->rightMargin) {
	    if (row_out) {
		*row_out = GET_ROW_FROM_COORD(y);
	    }
	    if (col_out) {
		*col_out = col;
	    }
	    return this_col;
	}
    }
    return 0;
}

static void actionActivate(Widget w, XEvent *event, String *params, Cardinal *num_params)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;
    XRectangle area;
    int x, y;
    int row, col;

    switch (event->type)
    {
	case KeyPress:
	case KeyRelease:
	    x = event->xkey.x;
	    y = event->xkey.y;
	    break;

	case ButtonPress:
	case ButtonRelease:
	    x = event->xbutton.x;
	    y = event->xbutton.y;
	    break;

	case MotionNotify:
	    x = event->xmotion.x;
	    y = event->xmotion.y;
	    break;

	default:
	    x = y = 0;
	    break;
    }

    this_col = XpGetCellFromCoord(w, x, y, &row, &col);

    if (this_col != 0 && this_col->doEvent != 0) {
	XSetBackground(XtDisplay(w), self->xpLinedArea.defaultGC, this_col->background);
	XSetForeground(XtDisplay(w), self->xpLinedArea.defaultGC, this_col->foreground);
	XSetFont(XtDisplay(w), self->xpLinedArea.defaultGC, this_col->font->fid);

	area.x = this_col->rightMargin - this_col->cellWidth - self->xpLinedArea.leftMargin;
	area.y = (row - self->xpLinedArea.topRow) * self->xpLinedArea.cellHeight;
	area.width = this_col->cellWidth;
	area.height = self->xpLinedArea.cellHeight;

	this_col->doEvent(w, self->xpLinedArea.defaultGC, this_col->font, &area,
			  event,
			  this_col->data, this_col->doEventClientData,
			  row, col);
    }
}

/*
** Simply call activate() on any event that the user *might* be
** interested in -- it's up to the user to figure out which events
** she really wants to handle (usually via a switch statement).
**
** This is obviously not very elegant, but having column-specific
** translation tables isn't very elegant either.
*/

static XtActionsRec actionList[] = { { "activate", actionActivate } };

static char defaultTranslations[] =
"<BtnDown>: activate() \n\
<BtnUp>: activate() \n\
<BtnMotion>: activate() \n\
<KeyDown>: activate() \n\
<KeyUp>: activate()";

static void setDefaultWidgetSize(XpLinedAreaWidget self)
{
    if (self->xpLinedArea.rows < 1) {
	self->xpLinedArea.rows = DEFAULT_ROW_COUNT;
    }

    if (self->xpLinedArea.visibleRows < 1) {
	self->xpLinedArea.visibleRows = DEFAULT_VISIBLE_ROW_COUNT;
    }

    if (self->xpLinedArea.cellHeight < 1) {
	if (self->xpLinedArea.font) {
	    self->xpLinedArea.cellHeight = self->xpLinedArea.font->ascent +
					   self->xpLinedArea.font->descent +
					   self->xpLinedArea.space;
	}
	else {
	    self->xpLinedArea.cellHeight = DEFAULT_CELL_HEIGHT;
	}
    }

    if (self->core.width == 0) {
	self->core.width = DEFAULT_CELL_WIDTH;
    }

    if (self->core.height < self->xpLinedArea.cellHeight) {
	self->core.height = self->xpLinedArea.cellHeight * self->xpLinedArea.visibleRows;
    }
}

static void paintRowBackgrounds(Display *d, Window w, GC gc, XpLinedAreaPart *info,
				int row, int stopRow, int x, int y, int width)
{
    int height;

#define IsColoredRow (((row - info->firstColoredRow) / info->colorAltRows) & 1) == 0

    XSetForeground(d, gc, info->altBackground);

    while (row < stopRow) {
	if (IsColoredRow) {
	    height = 0;

	    do {
		++row;
		height += info->cellHeight;
	    }
	    while (row < stopRow && IsColoredRow);

	    XFillRectangle(d, w, gc, x, y, width, height);

	    y += height;
	}

	++row;
	y += info->cellHeight;
    }
}

static void Redisplay(XpLinedAreaWidget self, XEvent *event, Region region)
{
    Display *display = XtDisplay(self);
    Window window = XtWindow(self);
    XpLinedAreaPart *info = &self->xpLinedArea;
    XpLinedAreaColumn *prev_col = 0;
    XpLinedAreaColumn *this_col = 0;
    int col = 0;
    int eventX, eventY, eventWidth, eventHeight;
    int startRow, stopRow, startY, stopY;
    XRectangle area;
    XGCValues gcValues;
    int temp, row;

    if (info->num_columns == 0) {
	return;
    }

    /* Interpret a nil event as a request to redisplaying everything. */

    if (event == 0) {
	eventX = 0;
	eventY = 0;
	eventWidth = self->core.width;
	eventHeight = self->core.height;
    }
    else {
	eventX = event->xexpose.x;
	eventY = event->xexpose.y;
	eventWidth = event->xexpose.width;
	eventHeight = event->xexpose.height;
    }

#define CoordToRow(C) (info->topRow + (C) / info->cellHeight)
#define RowToCoord(R) (((R) - info->topRow) * info->cellHeight)

    startRow = CoordToRow(eventY);
    stopRow = CoordToRow(eventY + eventHeight - 1) + 1;

    startY = RowToCoord(startRow);
    stopY = RowToCoord(stopRow);

    if (info->colorAltRows > 0) {
	paintRowBackgrounds(display, window, info->shadingGC, info,
			    startRow, stopRow, eventX, startY, eventWidth);
    }

    /* Skip over columns left of the exposure region. */

    while (eventX + info->leftMargin >= info->column[col]->rightMargin) {
	if (++col == info->num_columns) {
	    return;
	}
    }

    /* Display all the columns in the affected region. */

    for (;;) {
	prev_col = this_col;
	this_col = info->column[col];

	gcValues.background = this_col->background;
	gcValues.foreground = this_col->foreground;
	gcValues.font = this_col->font->fid;

	if (prev_col == 0) {
	    XChangeGC(display, info->defaultGC, GCBackground | GCForeground | GCFont, &gcValues);
	}
	else {
	    temp = 0;

	    if (this_col->background != prev_col->background)	    temp |= GCBackground;
	    if (this_col->foreground != prev_col->foreground)	    temp |= GCForeground;
	    if (this_col->font->fid != prev_col->font->fid)	    temp |= GCFont;

	    if (temp) {
		XChangeGC(display, info->defaultGC, temp, &gcValues);
	    }
	}

	area.x = this_col->rightMargin - this_col->cellWidth - info->leftMargin;
	area.y = startY;
	area.width = this_col->cellWidth;
	area.height = info->cellHeight;

	if (this_col->background != self->core.background_pixel) {
	    XSetForeground(display, info->shadingGC, this_col->background);
	    XFillRectangle(display, window, info->shadingGC,
			   area.x, area.y, area.width, stopY - startY);
	}

	if (this_col->doExpose != 0) {
	    for (row = startRow; row < stopRow; ++row) {
		this_col->doExpose((Widget)self, info->defaultGC, this_col->font, &area,
				   this_col->data, this_col->doExposeClientData,
				   row, col);
		area.y += area.height;
	    }
	}

	if (this_col->horizontalLineWidth > 0) {
	    gcValues.line_width = this_col->horizontalLineWidth - 1;
	    XChangeGC(display, info->defaultGC, GCLineWidth, &gcValues);

	    temp = startY;
	    for (row = startRow; row < stopRow; ++row) {
		XDrawLine(display, window, info->defaultGC,
			  area.x, temp, area.x + area.width - 1, temp);
		temp += area.height;
	    }
	}

	if (this_col->verticalLineWidth > 0) {
	    gcValues.line_width = this_col->verticalLineWidth - 1;
	    XChangeGC(display, info->defaultGC, GCLineWidth, &gcValues);

	    XDrawLine(display, window, info->defaultGC,
		      area.x + area.width - 1, startY, area.x + area.width - 1, stopY);
	}

	if (area.x + area.width >= eventX + eventWidth) {
	    return;
	}

	do {
	    if (++col == info->num_columns) {
		return;
	    }
	}
	while (info->column[col]->rightMargin <= 0);
    }
}

static void updateGenericScrollSize(XpLinedAreaWidget self, Widget scrollbar, int *top_pos,
				    int slider_size, int maximum)
{
    int old_maximum;
    int current_pos;

    /* Get the current state of the scrollbar.  This will be used
       in the event that the window size has changed and the scrollbar
       relationship needs to be recomputed. */

    XtVaGetValues(scrollbar,
		  XmNvalue, &current_pos,
		  XmNmaximum, &old_maximum,
		  0);

    /* If the user didn't give a maximum, just use the
       old value.  This simplifies other parts of the code. */

    if (maximum <= 0) maximum = old_maximum;

    /* If the slider size is less than 1, then Motif will complain.
       It is legitimate to have a slider size of 0, because that's
       the case when the scrolled window is zero height.  But we
       have to live with Motif... (basically, Motif scrollbars are not
       functional when the window size drops to a fraction of a row.) */

    if (slider_size <= 0) slider_size = 1;

    /* If the new slider size would make some rows past the
       maximum visible, the current position has to be pushed back
       a bit.  If not, the scrollbar will display a warning. */

    if (slider_size + current_pos > maximum)
    {
	/* If the current position has become negative, then the
	   slider size is too large (i.e. the window has grown
	   or columns have been shrunk).  Set the slider to be as
	   large as the entire data set because it all fits into
	   the window.  There may still be rows visible that are
	   past the maximum, but at least the scrollbar won't
	   complain about them. */

	if ((current_pos = maximum - slider_size) < 0)
	{
	    current_pos = 0;
	    slider_size = maximum;
	    *top_pos = 0;

	    /* If this routine was called in response to a resize,
	       then safeToUpdate is false -- the resize will take
	       care of the redisplay. */

	    if (XtIsRealized(self) && self->xpLinedArea.safeToUpdate)
	    {
		XClearWindow(XtDisplay(self), XtWindow(self));
		Redisplay(self, 0, 0);
	    }
	}
    }

    XtVaSetValues(scrollbar,
		  XmNvalue, current_pos,
		  XmNsliderSize, slider_size,
		  XmNpageIncrement, slider_size,
		  XmNmaximum, maximum,
		  0);
}

static void updateVScrollSize(XpLinedAreaWidget self, int slider_size, int maximum)
{
    updateGenericScrollSize(self, self->xpLinedArea.vScroll, &(self->xpLinedArea.topRow),
			    slider_size, maximum);
}

static void updateHScrollSize(XpLinedAreaWidget self, int slider_size, int maximum)
{
    updateGenericScrollSize(self, self->xpLinedArea.hScroll, &(self->xpLinedArea.leftMargin),
			    slider_size, maximum);
}

static void Realize(Widget w, XtValueMask *value_mask, XSetWindowAttributes *attributes)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    int width, maxRows;

    xpLinedAreaWidgetClass->core_class.superclass->core_class.realize(w, value_mask, attributes);

    self->xpLinedArea.defaultGC = XCreateGC(XtDisplay(w), XtWindow(w), 0, 0);
    self->xpLinedArea.shadingGC = XCreateGC(XtDisplay(w), XtWindow(w), 0, 0);

    if (self->xpLinedArea.hScroll != 0) {
	updateHScrollSize(self, self->core.width, self->xpLinedArea.width);
    }

    if (self->xpLinedArea.vScroll != 0) {
	updateVScrollSize(self, self->core.height / self->xpLinedArea.cellHeight, self->xpLinedArea.rows);
    }
}

static Boolean SetValues(Widget old_widget, Widget req_widget, Widget new_widget,
			 ArgList args, Cardinal *num_args)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)new_widget;
    int width, maxRows;

    setDefaultWidgetSize(self);

    if (self->xpLinedArea.hScroll != 0) {
	if (old_widget->core.width != self->core.width) {
	    updateHScrollSize(self, self->core.width, width);
	}
    }

    if (self->xpLinedArea.vScroll != 0) {
	if (old_widget->core.height != self->core.height) {
	    updateVScrollSize(self, self->core.height / self->xpLinedArea.cellHeight, self->xpLinedArea.rows);
	}
    }

    return(True);
}

static void Destroy(Widget w)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    if (self->xpLinedArea.defaultGC) {
	XFreeGC(XtDisplay(self), self->xpLinedArea.defaultGC);
    }

    if (self->xpLinedArea.shadingGC) {
	XFreeGC(XtDisplay(self), self->xpLinedArea.shadingGC);
    }
}

static void Resize(Widget w)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    if (XtIsRealized(self))
    {
	self->xpLinedArea.safeToUpdate = False;

	if (self->xpLinedArea.hScroll != 0) {
	    updateHScrollSize(self, self->core.width, 0);
	}

	if (self->xpLinedArea.vScroll != 0) {
	    updateVScrollSize(self, self->core.height / self->xpLinedArea.cellHeight, 0);
	}

	self->xpLinedArea.safeToUpdate = True;

	XClearWindow(XtDisplay(self), XtWindow(self));
	Redisplay(self, 0, 0);
    }
}

static void Highlight(Widget w)
{
}

static void UnHighlight(Widget w)
{
}

static void fillInColumnData(XpLinedAreaWidget self, XpLinedAreaColumn *this_col, va_list argv)
{
    XpLinedAreaColumnAttributes option;

    for (;;)
    {
	option = va_arg(argv, XpLinedAreaColumnAttributes);

	switch (option)
	{
	    case XpLinedAreaEnd:
		return;

	    case XpLinedAreaBackground:
		this_col->background = va_arg(argv, Pixel);
		break;

	    case XpLinedAreaForeground:
		this_col->foreground = va_arg(argv, Pixel);
		break;

	    case XpLinedAreaFont:
		this_col->font = va_arg(argv, XFontStruct *);
		break;

	    case XpLinedAreaWidth:
		/* va_arg(argv, Dimension) doesn't work.  Alignment problems? */
		this_col->cellWidth = (Dimension)va_arg(argv, int);
		break;

	    case XpLinedAreaData:
		this_col->data = va_arg(argv, void *);
		break;

	    case XpLinedAreaCallExpose:
		this_col->doExpose = va_arg(argv, XpLinedAreaExposeCallback);
		this_col->doExposeClientData = va_arg(argv, void *);
		break;

	    case XpLinedAreaCallEvent:
		this_col->doEvent = va_arg(argv, XpLinedAreaEventCallback);
		this_col->doEventClientData = va_arg(argv, void *);
		break;

	    case XpLinedAreaDisplayed:
		this_col->rightMargin = va_arg(argv, int);
		break;

	    case XpLinedAreaDivideHorizontal:
		this_col->horizontalLineWidth = va_arg(argv, int);
		break;

	    case XpLinedAreaDivideVertical:
		this_col->verticalLineWidth = va_arg(argv, int);
		break;

	    case XpLinedAreaRows:
		this_col->rows = va_arg(argv, int);
		if (this_col->rows < 0) {
		    this_col->rows = 0;
		}
		break;

	    default:
		break;
	}
    }
}

static void computeLogicalSize(XpLinedAreaWidget self)
{
    int rows = 0;
    int width = 0;
    XpLinedAreaColumn *this_col;
    int col;

    for (col = 0; col < self->xpLinedArea.num_columns; ++col) {
	this_col = self->xpLinedArea.column[col];

	if (this_col->rightMargin > 0) {
	    width += this_col->cellWidth;
	    this_col->rightMargin = width - 1;

	    if (this_col->rows > rows) {
		rows = this_col->rows;
	    }
	}
    }

    self->xpLinedArea.rows = rows;
    self->xpLinedArea.width = width;
    self->xpLinedArea.safeToUpdate = False;

    if (width > 0) {
	if (self->xpLinedArea.hScroll != 0) {
	    updateHScrollSize(self, self->core.width, width);
	}

	if (self->xpLinedArea.vScroll != 0) {
	    updateVScrollSize(self, self->core.height / self->xpLinedArea.cellHeight, rows);
	}
    }

    self->xpLinedArea.safeToUpdate = True;

    if (XtIsRealized(self)) {
	XClearWindow(XtDisplay(self), XtWindow(self));
	Redisplay(self, 0, 0);
    }
    else if (self->xpLinedArea.width <= self->xpLinedArea.maxDisplayWidth) {
	XtVaSetValues((Widget)self, XtNwidth, self->xpLinedArea.width, 0);
    }
}

static void RedisplayArea(XpLinedAreaWidget linedArea, Position x, Position y, Dimension w, Dimension h)
{
    XEvent event;

    event.xexpose.x = x;
    event.xexpose.y = y;
    event.xexpose.width = w;
    event.xexpose.height = h;

    XClearArea(XtDisplay(linedArea), XtWindow(linedArea), x, y, w, h, False);
    Redisplay(linedArea, &event, 0);
}

static void doHorzScrolling(Widget w, XtPointer clientData, XtPointer callData)
{
    XpLinedAreaWidget linedArea = (XpLinedAreaWidget)clientData;
    XmScrollBarCallbackStruct *status = (XmScrollBarCallbackStruct *)callData;
    XEvent event;

    XSync(XtDisplay(linedArea), False);
    while (XCheckWindowEvent(XtDisplay(linedArea), XtWindow(linedArea), ExposureMask, &event))
    {
	XtDispatchEvent(&event);
    }

    if (status->value != linedArea->xpLinedArea.leftMargin)
    {
	int left_margin = linedArea->xpLinedArea.leftMargin;
	int right_margin = left_margin + linedArea->core.width;

	int new_left_margin = status->value;
	int new_right_margin = new_left_margin + linedArea->core.width;

	linedArea->xpLinedArea.leftMargin = new_left_margin;

	if (left_margin < new_left_margin && new_left_margin < right_margin)
	{
	    int redraw_width = new_left_margin - left_margin;
	    int copy_width = right_margin - new_left_margin;

	    XCopyArea(XtDisplay(linedArea), XtWindow(linedArea), XtWindow(linedArea),
		      linedArea->xpLinedArea.defaultGC,
		      redraw_width, 0,
		      copy_width, linedArea->core.height,
		      0, 0);

	    RedisplayArea(linedArea, copy_width, 0, redraw_width, linedArea->core.height);
	}
	else if (left_margin < new_right_margin && new_right_margin < right_margin)
	{
	    int redraw_width = left_margin - new_left_margin;
	    int copy_width = new_right_margin - left_margin;

	    XCopyArea(XtDisplay(linedArea), XtWindow(linedArea), XtWindow(linedArea),
		      linedArea->xpLinedArea.defaultGC,
		      0, 0,
		      copy_width, linedArea->core.height,
		      redraw_width, 0);

	    RedisplayArea(linedArea, 0, 0, redraw_width, linedArea->core.height);
	}
	else
	{
	    XClearWindow(XtDisplay(linedArea), XtWindow(linedArea));
	    Redisplay(linedArea, 0, 0);
	}
    }
}

static void doVertScrolling(Widget w, XtPointer clientData, XtPointer callData)
{
    XpLinedAreaWidget linedArea = (XpLinedAreaWidget)clientData;
    XmScrollBarCallbackStruct *status = (XmScrollBarCallbackStruct *)callData;
    XEvent event;

    XSync(XtDisplay(linedArea), False);
    while (XCheckWindowEvent(XtDisplay(linedArea), XtWindow(linedArea), ExposureMask, &event))
    {
	XtDispatchEvent(&event);
    }

    if (status->value != linedArea->xpLinedArea.topRow)
    {
	unsigned int rows_displayed = linedArea->core.height / linedArea->xpLinedArea.cellHeight;

	unsigned int top_row = linedArea->xpLinedArea.topRow;
	unsigned int last_row = top_row + rows_displayed;

	unsigned int new_top_row = status->value;
	unsigned int new_last_row = new_top_row + rows_displayed;

	linedArea->xpLinedArea.topRow = new_top_row;

	if (top_row < new_top_row && new_top_row < last_row)
	{
	    int source_y = (new_top_row - top_row) * linedArea->xpLinedArea.cellHeight;
	    int copy_height = (last_row - new_top_row) * linedArea->xpLinedArea.cellHeight;

	    XCopyArea(XtDisplay(linedArea), XtWindow(linedArea), XtWindow(linedArea),
		      linedArea->xpLinedArea.defaultGC,
		      0, source_y,
		      linedArea->core.width, copy_height,
		      0, 0);

	    RedisplayArea(linedArea, 0, copy_height, linedArea->core.width,
			  linedArea->core.height - copy_height);
	}
	else if (top_row < new_last_row && new_last_row < last_row)
	{
	    int dest_y = (top_row - new_top_row) * linedArea->xpLinedArea.cellHeight;

	    XCopyArea(XtDisplay(linedArea), XtWindow(linedArea), XtWindow(linedArea),
		      linedArea->xpLinedArea.defaultGC,
		      0, 0,
		      linedArea->core.width, linedArea->core.height - dest_y,
		      0, dest_y);

	    RedisplayArea(linedArea, 0, 0, linedArea->core.width, dest_y);
	}
	else
	{
	    XClearWindow(XtDisplay(linedArea), XtWindow(linedArea));
	    Redisplay(linedArea, 0, 0);
	}
    }
}

static void handleGraphicsExpose(Widget w, XtPointer client_data, XEvent *event, Boolean *continue_dispatch)
{
    /* GraphicsExpose is a special non-maskable event the occurs when a
       drawing source requires redrawing during a region copy. */

    if (event->type == GraphicsExpose) {
	Redisplay((XpLinedAreaWidget)w, event, 0);
    }
}

static void Initialize(Widget req_widget, Widget new_widget, ArgList args, Cardinal *num_args)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)new_widget;
    Widget parent = XtParent(self);

    setDefaultWidgetSize(self);

    self->xpLinedArea.safeToUpdate = True;

    self->xpLinedArea.num_columns = 0;
    self->xpLinedArea.max_columns = 0;
    self->xpLinedArea.column = 0;

    self->xpLinedArea.defaultGC = 0;
    self->xpLinedArea.shadingGC = 0;

    self->xpLinedArea.topRow = 0;
    self->xpLinedArea.leftMargin = 0;
    self->xpLinedArea.width = 0;

    self->xpLinedArea.hScroll = 0;
    self->xpLinedArea.vScroll = 0;

    XtAddEventHandler((Widget)self, NoEventMask, True, handleGraphicsExpose, 0);

    if (parent && XtClass(parent) == xmScrolledWindowWidgetClass)
    {
	self->xpLinedArea.hScroll = XtVaCreateManagedWidget("hScroll", xmScrollBarWidgetClass, parent,
							  XmNorientation, XmHORIZONTAL,
							  XmNminimum, 0,
							  XmNmaximum, self->core.width,
							  0);

	self->xpLinedArea.vScroll = XtVaCreateManagedWidget("vScroll", xmScrollBarWidgetClass, parent,
							  XmNorientation, XmVERTICAL,
							  XmNminimum, 0,
							  XmNmaximum, self->xpLinedArea.rows,
							  0);

	XtAddCallback(self->xpLinedArea.hScroll, XmNvalueChangedCallback, doHorzScrolling, self);
	XtAddCallback(self->xpLinedArea.hScroll, XmNdragCallback, doHorzScrolling, self);

	XtAddCallback(self->xpLinedArea.vScroll, XmNvalueChangedCallback, doVertScrolling, self);
	XtAddCallback(self->xpLinedArea.vScroll, XmNdragCallback, doVertScrolling, self);

	XmScrolledWindowSetAreas(parent, self->xpLinedArea.hScroll, self->xpLinedArea.vScroll, (Widget)self);

	self->primitive.highlight_thickness = 2;
    }
}

/* Class record declaration */

XpLinedAreaClassRec xpLinedAreaClassRec =
{
    /* Core class part */

    {
	/* superclass               */ (WidgetClass)&xmPrimitiveClassRec,
	/* class_name               */ "XpLinedArea",
	/* widget_size              */ sizeof(XpLinedAreaRec),
	/* class_initialize         */ 0,
	/* class_part_initialize    */ 0,
	/* class_inited             */ False,
	/* initialize               */ Initialize,
	/* initialize_hook          */ 0,
	/* realize                  */ Realize,
	/* actions                  */ actionList,
	/* num_actions              */ XtNumber(actionList),
	/* resources                */ resources,
	/* num_resources            */ XtNumber(resources),
	/* xrm_class                */ NULLQUARK,
	/* compress_motion          */ True,
	/* compress_exposure        */ XtExposeCompressMultiple,
	/* compress_enterleave      */ True,
	/* visible_interest         */ False,
	/* destroy                  */ Destroy,
	/* resize                   */ Resize,
	/* expose                   */ (XtExposeProc)Redisplay,
	/* set_values               */ SetValues,
	/* set_values_hook          */ 0,
	/* set_values_almost        */ XtInheritSetValuesAlmost,
	/* get_values_hook          */ 0,
	/* accept_focus             */ XtInheritAcceptFocus,
	/* version                  */ XtVersion,
	/* callback offsets         */ 0,
	/* tm_table                 */ defaultTranslations,
	/* query_geometry           */ XtInheritQueryGeometry,
	/* display_accelerator      */ 0,
	/* extension                */ 0
    },

    /* Primitive class part */

    {
	/* border_highlight          */ Highlight,
	/* border_unhighlight        */ UnHighlight,
	/* translations              */ XtInheritTranslations,
	/* arm_and_activate          */ 0,
	/* get_resources       	     */ 0,
	/* num get_resources         */ 0,
	/* extension                 */ 0,
    },

    /* XpLinedArea class part */

    {
	/* example so I remember...  */ 0
    }
};

/* Class record pointer */

WidgetClass xpLinedAreaWidgetClass = (WidgetClass)&xpLinedAreaClassRec;

void XpLinedAreaInsertColumn(Widget w, int col, void *data, ...)
{
    va_list argv;
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col = 0;
    int last = self->xpLinedArea.num_columns;
    int i;

    if (col < 0 || col > last) {
	col = last;
    }

    if (self->xpLinedArea.max_columns <= col)
    {
	int new_max = (last + 4) & ~0x03;
	XpLinedAreaColumn **new_column = (XpLinedAreaColumn **)XtMalloc(sizeof(XpLinedAreaColumn *) * new_max);

	if (new_column) {
	    for (i = 0; i < self->xpLinedArea.max_columns; ++i) {
		new_column[i] = self->xpLinedArea.column[i];
	    }
	    for (; i < new_max; ++i) {
		new_column[i] = 0;
	    }
	    XtFree((char *)self->xpLinedArea.column);
	    self->xpLinedArea.max_columns = new_max;
	    self->xpLinedArea.column = new_column;
	}
	else {
	    return;
	}
    }

    this_col = (XpLinedAreaColumn *)XtMalloc(sizeof(XpLinedAreaColumn));

    this_col->rows = 0;

    this_col->rightMargin = True;
    this_col->cellWidth = DEFAULT_CELL_WIDTH;

    this_col->data = data;

    this_col->horizontalLineWidth = 0;
    this_col->verticalLineWidth = 1;

    this_col->foreground = self->xpLinedArea.foreground;
    this_col->background = self->core.background_pixel;
    this_col->font = self->xpLinedArea.font;

    this_col->doExpose = 0;
    this_col->doExposeClientData = 0;
    this_col->doEvent = 0;
    this_col->doEventClientData = 0;

    for (i = last - 1; i >= col; --i) {
	self->xpLinedArea.column[i + 1] = self->xpLinedArea.column[i];
    }

    self->xpLinedArea.column[col] = this_col;
    ++self->xpLinedArea.num_columns;

    va_start(argv, data);
    fillInColumnData(self, this_col, argv);
    va_end(argv);

    computeLogicalSize(self);
}

void XpLinedAreaChangeColumn(Widget w, int col, ...)
{
    va_list argv;
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;

    if (col < self->xpLinedArea.num_columns) {
	this_col = self->xpLinedArea.column[col];

	va_start(argv, col);
	fillInColumnData(self, this_col, argv);
	va_end(argv);

	computeLogicalSize(self);
    }
}

void XpLinedAreaRedraw(Widget w)
{
    if (XtIsRealized(w)) {
	XClearArea(XtDisplay(w), XtWindow(w), 0, 0, 0, 0, True);
    }
}

void XpLinedAreaGetCellClipArea(Widget w, int row, int col, XRectangle *area)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;
    int x, y, width, height;

    area->width = 0;

    if (col < self->xpLinedArea.num_columns) {
	this_col = self->xpLinedArea.column[col];

	row -= self->xpLinedArea.topRow;

	if (row >= 0) {
	    x = this_col->rightMargin - this_col->cellWidth - self->xpLinedArea.leftMargin;
	    y = row * self->xpLinedArea.cellHeight;
	    width = this_col->cellWidth;
	    height = self->xpLinedArea.cellHeight;

	    if (x < 0) {
		width += x;
		x = 0;
	    }

	    if (x + width > self->core.width) {
		width = self->core.width - x;
	    }

	    if (y < self->core.height) {
		if (y + height > self->core.height) {
		    height = self->core.height - y;
		}

		area->x = (short)x;
		area->y = (short)y;
		area->width = (unsigned short)width;
		area->height = (unsigned short)height;
	    }
	}
    }
}

void XpLinedAreaRedrawColumn(Widget w, int col, Boolean should_display)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;

    if (col < self->xpLinedArea.num_columns) {
	this_col = self->xpLinedArea.column[col];

	if (this_col->rightMargin > 0 && should_display) {
	    if (XtIsRealized(w)) {
		XRectangle area;

		XpLinedAreaGetCellClipArea(w, 0, col, &area);

		if (area.width > 0) {
		    area.y = 0;
		    area.height = self->core.height;

		    RedisplayArea(self, area.x, area.y, area.width, area.height);
		}
	    }
	    return;
	}
	else if (this_col->rightMargin <= 0 && !should_display) {
	    return;
	}

	this_col->rightMargin = should_display;

	computeLogicalSize(self);
    }
}

void XpLinedAreaRedrawCell(Widget w, int row, int col)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XpLinedAreaColumn *this_col;
    XRectangle area;

    XpLinedAreaGetCellClipArea(w, row, col, &area);

    if (area.width > 0) {
	RedisplayArea(self, area.x, area.y, area.width, area.height);
    }
}

int XpLinedAreaGetCellHeight(Widget w)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    return self->xpLinedArea.cellHeight;
}

int XpLinedAreaGetCurrentRow(Widget w)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    return self->xpLinedArea.topRow;
}

int XpLinedAreaGetRows(Widget w)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    return self->xpLinedArea.rows;
}

void XpLinedAreaScrollToRow(Widget w, int row)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;
    XmScrollBarCallbackStruct vscrollto;
    int rows_displayed = self->core.height / self->xpLinedArea.cellHeight;

    if (row + rows_displayed > self->xpLinedArea.rows) {
	row = self->xpLinedArea.rows - rows_displayed;
    }

    if (row < 0) {
	row = 0;
    }

    vscrollto.value = row;
    vscrollto.reason = 0;
    vscrollto.event = 0;
    vscrollto.pixel = 0;

    doVertScrolling(0, (XtPointer)w, (XtPointer)&vscrollto);

    if (self->xpLinedArea.vScroll) {
	XtVaSetValues(self->xpLinedArea.vScroll, XmNvalue, row, 0);
    }
}

void XpLinedAreaScrollHandler(Widget w, XEvent *event)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    if (event->type == KeyRelease)
    {
	int top = self->xpLinedArea.topRow;
	unsigned int rows_displayed = self->core.height / self->xpLinedArea.cellHeight;
	unsigned int k = XKeycodeToKeysym(XtDisplay(self), event->xkey.keycode, 0);

	switch (k)
	{
	    case XK_Up:
		top = top - 1;
		break;

	    case XK_Page_Up:
		top = top - rows_displayed + 1;
		break;

	    case XK_Down:
		top = top + 1;
		break;

	    case XK_Page_Down:
		top = top + rows_displayed - 1;
		break;
	}

	XpLinedAreaScrollToRow(w, top);
    }
}

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static SV *get_field(HV *hash, char *field, int field_len)
{
    if (hash) {
	SV **entry = hv_fetch(hash, field, field_len, FALSE);
	if (entry && SvOK(*entry)) {
	    return *entry;
	}
    }

    return 0;
}

static SV *get_element(AV *array, int row)
{
    if (array) {
	SV **entry = av_fetch(array, row, FALSE);
	if (entry && SvOK(*entry)) {
	    return *entry;
	}
    }

    return 0;
}

static char *get_string(SV *scalar, int *str_len)
{
    char *str = 0;

    if (scalar && SvOK(scalar)) {
	STRLEN len;
	str = SvPV(scalar, len);
	*str_len = (int)len;
    }

    return str;
}

static int get_integer(SV *scalar)
{
    if (scalar && SvOK(scalar)) {
	return SvIV(scalar);
    }

    return 0;
}

static HV *get_hash(SV *scalar)
{
    if (scalar && SvROK(scalar)) {
	HV *hash = (HV *)SvRV(scalar);
        if (SvTYPE(hash) == SVt_PVHV) {
	    return hash;
	}
    }

    return 0;
}

static AV *get_array(SV *scalar)
{
    if (scalar && SvROK(scalar)) {
	AV *array = (AV *)SvRV(scalar);
        if (SvTYPE(array) == SVt_PVAV) {
	    return array;
	}
    }

    return 0;
}

static void draw_arrow(Display *d, Window w, GC gc, short x, short y, int height)
{
    static XPoint vertices[] = {
	{  0,   0 },
	{  5,   6 },
	{ -5,   6 },
	{  0, -12 },
    };

    height = (height - 12) / 2;

    vertices[0].x = x;
    vertices[0].y = y + height;

    XFillPolygon(d, w, gc, vertices, 4, Convex, CoordModePrevious);
}

void xp_outliner_expose_handler(Widget w, GC gc, XFontStruct *font, XRectangle *area,
				void *column_data, void *client_data,
				int row, int col)
{
    XpLinedAreaWidget self = (XpLinedAreaWidget)w;

    HV *perl_obj = get_hash((SV *)column_data);
    AV *perl_array;
    HV *perl_cell;

    perl_array = get_array(get_field(perl_obj, "-outline", 8));
    perl_cell = get_hash(get_element(perl_array, row));

    if (perl_cell) {
	char *label;
	int label_len;

	switch (col) {
	    case 0:
		label = get_string(get_field(perl_cell, "-label", 6), &label_len);

		if (label && label_len > 0) {
		    XGCValues gc_values;

		    int indent = get_integer(get_field(perl_cell, "-indent", 7)) *
			         self->xpLinedArea.indentationIncr;
		    int flags = get_integer(get_field(perl_cell, "-flags", 6));

		    if (flags & 1) {
			int direction, ascent, descent;
			XCharStruct info;

			XTextExtents(font, label, label_len, &direction, &ascent, &descent, &info);
			XFillRectangle(XtDisplay(w), XtWindow(w), gc,
				       area->x + indent, area->y,
				       info.rbearing + info.lbearing, area->height);
			XGetGCValues(XtDisplay(w), gc, GCForeground, &gc_values);
			XSetForeground(XtDisplay(w), gc, XWhitePixelOfScreen(XtScreen(w)));
		    }

		    XDrawString(XtDisplay(w), XtWindow(w), gc,
				area->x + indent, area->y + area->height - font->descent,
				label, label_len);

		    if (flags & 1) {
			XSetForeground(XtDisplay(w), gc, gc_values.foreground);
		    }

		    if (flags & 32) {
			draw_arrow(XtDisplay(w), XtWindow(w), gc,
				   area->x + self->xpLinedArea.indentationIncr / 2, area->y,
				   area->height);
		    }
		}
		break;

	    default:
		--col;
		perl_array = get_array(get_field(perl_cell, "-desc", 5));
		if (perl_array && col <= AvFILL(perl_array)) {
		    label = get_string(get_element(perl_array, col), &label_len);

		    if (label && label_len > 0) {
			XDrawString(XtDisplay(w), XtWindow(w), gc,
				    area->x, area->y + area->height - font->descent,
				    label, label_len);
		    }
		}
		break;
	}
    }
}

extern char *XEventPtr_Package(int id);

int call_perl_handler(SV *handler, Widget w, SV *obj, XEvent *event,
		      int clicks, int row, int col)
{
    int result = 0;
    int count;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_setref_pv(sv_newmortal(), "X::Toolkit::Widget", w));
    XPUSHs(obj);
    XPUSHs(sv_setref_pv(sv_newmortal(), XEventPtr_Package(event->type), event));
    XPUSHs(sv_2mortal(newSViv(clicks)));
    XPUSHs(sv_2mortal(newSViv(row)));
    XPUSHs(sv_2mortal(newSViv(col)));
    PUTBACK;

    count = perl_call_sv(handler, G_SCALAR);

    SPAGAIN;

    if (count == 1) {
	result = POPi;
    }

    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

void xp_outliner_event_handler(Widget w, GC gc, XFontStruct *font, XRectangle *area,
			       XEvent *event,
			       void *column_data, void *client_data,
			       int row, int col)
{
    switch (call_perl_handler((SV *)client_data, w, (SV *)column_data, event, 0, row, col)) {
	case 0:
	    /* no redraw needed */
	    return;
	case 1:
	    XpLinedAreaRedrawCell(w, row, col);
	    return;
	case 2:
	    XpLinedAreaRedraw(w);
	    return;
	default:
	    break;
    }

    XpLinedAreaScrollHandler(w, event);
}
