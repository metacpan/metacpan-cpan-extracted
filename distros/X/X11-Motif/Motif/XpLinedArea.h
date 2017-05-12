
#ifndef XPLINEDAREA_H
#define XPLINEDAREA_H

#ifdef __cplusplus
extern "C" {
#endif

/* Reference to the class record pointer */

extern WidgetClass xpLinedAreaWidgetClass;

/* Resource definitions */

#define XtNrows			"rows"
#define XtCRows			"Rows"
#define XtNvisibleRows		"visibleRows"
#define XtCVisibleRows		"VisibleRows"
#define XtNcellHeight		"cellHeight"
#define XtCCellHeight		"CellHeight"
#define XtNmaxDisplayWidth	"maxDisplayWidth"
#define XtCMaxDisplayWidth	"MaxDisplayWidth"
#define XtNcolorAltRows		"colorAltRows"
#define XtCColorAltRows		"ColorAltRows"
#define XtNfirstColoredRow	"firstColoredRow"
#define XtCFirstColoredRow	"FirstColoredRow"
#define XtNaltBackground	"altBackground"
#define XtCAltBackground	"AltBackground"
#define XtNindentationIncr	"indentationIncr"
#define XtCIndentationIncr	"IndentationIncr"
#define XtNinternalPadding	"internalPadding"
#define XtCInternalPadding	"InternalPadding"

/* Custom type definitions */

typedef enum XpLinedAreaColumnAttributesEnum
{
    XpLinedAreaEnd = 0,
    XpLinedAreaOrder,

    XpLinedAreaRows,

    XpLinedAreaDisplayed,
    XpLinedAreaData,

    XpLinedAreaWidth,
    XpLinedAreaDivideHorizontal,
    XpLinedAreaDivideVertical,

    XpLinedAreaBackground,
    XpLinedAreaForeground,
    XpLinedAreaFont,

    XpLinedAreaCallExpose,
    XpLinedAreaCallEvent

} XpLinedAreaColumnAttributes;

typedef void (*XpLinedAreaExposeCallback)(Widget, GC, XFontStruct *, XRectangle *,
					  void *column_data, void *client_data,
					  int row, int column);

typedef void (*XpLinedAreaEventCallback)(Widget, GC, XFontStruct *, XRectangle *,
					 XEvent *,
					 void *column_data, void *client_data,
					 int row, int column);

typedef struct XpLinedAreaColumnStruct
{
    int rows;					/* number of rows in this column */

    int rightMargin;				/* x coordinate of right margin if displayed, else 0 */
    int cellWidth;				/* width of the column */

    XtPointer data;				/* extra user data associated with entire column */

    Dimension horizontalLineWidth;		/* row divider line width (0 = no divider) */
    Dimension verticalLineWidth;		/* column divider line width (0 = no divider) */

    Pixel foreground;				/* default foreground for column */
    Pixel background;				/* column background overlays row background */
    XFontStruct *font;				/* default font for column */

    XpLinedAreaExposeCallback doExpose;		/* user's column (cell) expose handler */
    void *doExposeClientData;			/* extra user data to pass to expose handler */
    XpLinedAreaEventCallback doEvent;		/* user's column (cell) event handler */
    void *doEventClientData;			/* extra user data to pass to event handler */
}
XpLinedAreaColumn;

/* Custom method declarations */

void XpLinedAreaInsertColumn(Widget w, int col, void *data, ...);
void XpLinedAreaChangeColumn(Widget w, int col, ...);

void XpLinedAreaRedraw(Widget w);
void XpLinedAreaRedrawColumn(Widget w, int col, Boolean should_display);
void XpLinedAreaRedrawCell(Widget w, int row, int col);

void XpLinedAreaScrollToRow(Widget w, int row);
void XpLinedAreaScrollHandler(Widget w, XEvent *event);

int XpGetRowFromCoord(Widget w, int y);
XpLinedAreaColumn *XpGetCellFromCoord(Widget w, int x, int y, int *row_out, int *col_out);
void XpLinedAreaGetCellClipArea(Widget w, int row, int col, XRectangle *area);
int XpLinedAreaGetCellHeight(Widget w);
int XpLinedAreaGetCurrentRow(Widget w);
int XpLinedAreaGetRows(Widget w);

typedef struct XpOutlineStyleStruct
{
    /* These attributes are used for specializing the display of a row
       displayed in an XpOutline */

    Pixmap icon;
    Pixmap icon_mask;
    XFontStruct *font;

    GC gc;					/* custom graphics context for this style */
}
XpOutlineStyle;

void xp_outliner_expose_handler(Widget w, GC gc, XFontStruct *font, XRectangle *area,
				void *column_data, void *client_data,
				int row, int column);

void xp_outliner_event_handler(Widget w, GC gc, XFontStruct *font, XRectangle *area,
			       XEvent *event,
			       void *column_data, void *client_data,
			       int row, int column);

#ifdef __cplusplus
};
#endif

#endif
