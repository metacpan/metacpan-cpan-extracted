
#include "toolkit-api.h"

#include <Xm/Xm.h>
#include <Xm/ArrowB.h>
#include <Xm/BulletinB.h>
#include <Xm/CascadeB.h>
#include <Xm/Command.h>
#include <Xm/DialogS.h>
#include <Xm/DrawingA.h>
#include <Xm/DrawnB.h>
#include <Xm/FileSB.h>
#include <Xm/Form.h>
#include <Xm/Frame.h>
#include <Xm/Label.h>
#include <Xm/List.h>
#include <Xm/MainW.h>
#include <Xm/MenuShell.h>
#include <Xm/MessageB.h>
#include <Xm/PanedW.h>
#include <Xm/PushB.h>
#include <Xm/RowColumn.h>
#include <Xm/Scale.h>
#include <Xm/Screen.h>
#include <Xm/ScrollBar.h>
#include <Xm/ScrolledW.h>
#include <Xm/SelectioB.h>
#include <Xm/Separator.h>
#include <Xm/Text.h>
#include <Xm/TextF.h>
#include <Xm/ToggleB.h>

#include "XpFolder.h"
#include "XpStack.h"
#include "XpLinedArea.h"

#ifdef WANT_XBAE
#include <Xbae/Matrix.h>
#include <Xbae/Caption.h>
#endif

extern char *XmString_Package;
extern char *XmAnyCallbackStructPtr_Package;
extern char *XmArrowButtonCallbackStructPtr_Package;
extern char *XmDrawingAreaCallbackStructPtr_Package;
extern char *XmDrawnButtonCallbackStructPtr_Package;
extern char *XmPushButtonCallbackStructPtr_Package;
extern char *XmRowColumnCallbackStructPtr_Package;
extern char *XmScrollBarCallbackStructPtr_Package;
extern char *XmToggleButtonCallbackStructPtr_Package;
extern char *XmListCallbackStructPtr_Package;
extern char *XmSelectionBoxCallbackStructPtr_Package;
extern char *XmCommandCallbackStructPtr_Package;
extern char *XmFileSelectionBoxCallbackStructPtr_Package;
extern char *XmScaleCallbackStructPtr_Package;
extern char *XmTextVerifyCallbackStructPtr_Package;
extern char *XmTraverseObscuredCallbackStructPtr_Package;

extern char *wchar_tPtr_Package;

extern char *XmFontContext_Package;
extern char *XmFontList_Package;
extern char *XmFontListEntry_Package;
extern char *XmFontType_Package;
extern char *XmStringCharSet_Package;
extern char *XmTextSource_Package;
extern char *XmStringContext_Package;
