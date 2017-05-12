
#ifndef XPFOLDER_H
#define XPFOLDER_H

#include "XpStack.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Reference to the class record pointer */

extern WidgetClass xpFolderWidgetClass;

/* Resource definitions */

#define XtNtabPosition		"tabPosition"
#define XtCTabPosition		"TabPosition"
#define XtRTabPosition		XtCTabPosition
#define XtNtabAlignment		"tabAlignment"
#define XtCTabAlignment		"TabAlignment"
#define XtRTabAlignment		XtCTabAlignment
#define XtNallowScrollingTabs	"allowScrollingTabs"
#define XtCAllowScrollingTabs	"AllowScrollingTabs"
#define XtNtabFont		"tabFont"
#define XtCTabFont		"TabFont"
#define XtNtabHeight		"tabHeight"
#define XtCTabHeight		"TabHeight"
#define XtNtabSlantWidth	"tabSlantWidth"
#define XtCTabSlantWidth	"TabSlantWidth"
#define XtNtabMargin		"tabMargin"
#define XtCTabMargin		"TabMargin"
#define XtNtopFolderColor	"topFolderColor"
#define XtCTopFolderColor	"TopFolderColor"
#define XtNbottomFolderColor	"bottomFolderColor"
#define XtCBottomFolderColor	"BottomFolderColor"

#define XtNstackWidget		"stackWidget"
#define XtCStackWidget		"StackWidget"

#ifdef __cplusplus
};
#endif

extern void XpFolderRedisplayTabsNotify(Widget xpFolder);
extern void XpFolderTabsChangedNotify(Widget xpFolder);

#endif
