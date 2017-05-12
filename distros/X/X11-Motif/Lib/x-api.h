
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xresource.h>

#ifdef NEEDS_PIXEL
typedef unsigned long Pixel;
#endif

extern char *XID_Package;
extern char *Window_Package;
extern char *Drawable_Package;
extern char *Font_Package;
extern char *Pixmap_Package;
extern char *Cursor_Package;
extern char *Colormap_Package;
extern char *GContext_Package;
extern char *KeySym_Package;
extern char *EventMask_Package;

extern char *Atom_Package;
extern char *VisualID_Package;
extern char *Time_Package;
extern char *KeyCode_Package;
extern char *XContext_Package;
extern char *Pixel_Package;

extern char *XrmQuark_Package;
extern char *XrmName_Package;
extern char *XrmClass_Package;
extern char *XrmRepresentation_Package;
extern char *XrmString_Package;
extern char *XrmDatabase_Package;
extern char *XrmOptionDescRecPtr_Package;
extern char *XrmValuePtr_Package;

extern char *DisplayPtr_Package;
extern char *GC_Package;
extern char *ScreenPtr_Package;
extern char *VisualPtr_Package;
extern char *XColorPtr_Package;
extern char *XGCValuesPtr_Package;
extern char *XHostAddressPtr_Package;
extern char *XImagePtr_Package;
extern char *XArcPtr_Package;
extern char *XChar2bPtr_Package;
extern char *XCharStructPtr_Package;
extern char *XFontSet_Package;
extern char *XFontSetExtentsPtr_Package;
extern char *XFontStructPtr_Package;
extern char *XKeyboardControlPtr_Package;
extern char *XKeyboardStatePtr_Package;
extern char *XModifierKeymapPtr_Package;
extern char *XPixmapFormatValuesPtr_Package;
extern char *XPointPtr_Package;
extern char *XRectanglePtr_Package;
extern char *XSegmentPtr_Package;
extern char *XSetWindowAttributesPtr_Package;
extern char *XTextItemPtr_Package;
extern char *XTextItem16Ptr_Package;
extern char *XTimeCoordPtr_Package;
extern char *XWindowAttributesPtr_Package;
extern char *XWindowChangesPtr_Package;
extern char *Region_Package;
extern char *XClassHintPtr_Package;
extern char *XComposeStatusPtr_Package;
extern char *XIconSizePtr_Package;
extern char *XSizeHintsPtr_Package;
extern char *XStandardColormapPtr_Package;
extern char *XTextPropertyPtr_Package;
extern char *XVisualInfoPtr_Package;
extern char *XWMHintsPtr_Package;

extern char *XKeyEventPtr_Package;
extern char *XMappingEventPtr_Package;
extern char *XButtonPressedEventPtr_Package;
extern char *XSelectionRequestEventPtr_Package;

char *XEventPtr_Package(int id);
