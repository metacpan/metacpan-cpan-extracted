
#ifndef XPLINEDAREAP_H
#define XPLINEDAREAP_H

#include "XpLinedArea.h"

/* Define the linedArea instance part */

typedef struct
{
    /* New resource fields */

    Dimension space;		/* space to leave around the border of an cell */
    int rows;			/* The number of rows in the longest column */
    int visibleRows;		/* The number of rows visible at once */
    Dimension cellHeight;	/* calculated height of an cell */
    Dimension maxDisplayWidth;	/* don't allow the widget to automatically resize larger than this */
    Pixel foreground;		/* default cell foreground color */
    XFontStruct *font;		/* default cell font */
    int colorAltRows;		/* if > 0, then color alternate blocks of N rows */
    int firstColoredRow;	/* when coloring rows, this is the row to start on */
    Pixel altBackground;	/* color of background used in alternate rows */

    /* These resources are used when in outline mode */

    int indentationIncr;	/* how far each level should be indented */
    int internalPadding;	/* space (pixels) between icon, label and margin */

    /* New internal fields */

    Boolean safeToUpdate;	/* should update when switching columns or updating */
    int num_columns;		/* number of columns in column[] */
    int max_columns;		/* size of column[] allocation */
    XpLinedAreaColumn **column;	/* array of columns being displayed */
    GC defaultGC;		/* GC for drawing column data */
    GC shadingGC;		/* GC for drawing column background and highlights */
    int topRow;			/* row number of first row displayed */
    int leftMargin;		/* pixel offset of the left margin after scrolling */
    int width;			/* combined width of all displayed columns */
    Widget hScroll;		/* scroll bars used when embedded in a scrolling window */
    Widget vScroll;
}
XpLinedAreaPart;

/* Define the full instance record */

typedef struct _LinedAreaRec
{
    CorePart core;
    XmPrimitivePart primitive;
    XpLinedAreaPart xpLinedArea;
}
XpLinedAreaRec, *XpLinedAreaWidget;

/* Define class part structure */

typedef struct
{
    int likeThis;
}
XpLinedAreaClassPart;

/* Define the full class record */

typedef struct _LinedAreaClassRec
{
    CoreClassPart core_class;
    XmPrimitiveClassPart primitive_class;
    XpLinedAreaClassPart xpLinedArea_class;
}
XpLinedAreaClassRec, *XpLinedAreaWidgetClass;

/* External definition for class record */

extern XpLinedAreaClassRec xpLinedAreaClassRec;

#endif
