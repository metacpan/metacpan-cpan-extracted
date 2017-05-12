
#ifndef _XPSTACK_H
#define _XPSTACK_H

#include <X11/Constraint.h>

#if defined(__cplusplus)
extern "C" {
#endif

/* Reference to the class record pointer */

extern WidgetClass xpStackWidgetClass;

/* Resource definitions */

extern int XpStackChildWidgetOrder(Widget child);
extern int XpStackNumChildren(Widget stack);
extern void XpStackNextWidget(Widget stack);
extern void XpStackPreviousWidget(Widget stack);
extern void XpStackGotoWidget(Widget stack, int child);
extern void XpStackSetActiveChild(Widget w, int i);
extern int XpStackGetActiveChild(Widget w);

#define XtNoutsideMargin	"outsideMargin"
#define XtCOutsideMargin	"OutsideMargin"
#define XtNlayerName		"layerName"
#define XtCLayerName		"LayerName"
#define XtNlayerActive		"layerActive"
#define XtCLayerActive		"LayerActive"

#define XtNnowDisplayedCallback	"nowDisplayedCallback"
#define XtNnowHiddenCallback	"nowHiddenCallback"

#if defined(__cplusplus)
};
#endif

#endif /* _XPSTACK_H */
