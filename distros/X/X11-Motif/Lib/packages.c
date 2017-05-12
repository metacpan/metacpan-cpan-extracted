
#include <X11/Xlib.h>

char *XID_Package = "X::ID";
char *Window_Package = "X::Window";
char *Drawable_Package = "X::Drawable";
char *Font_Package = "X::Font";
char *Pixmap_Package = "X::Pixmap";
char *Cursor_Package = "X::Cursor";
char *Colormap_Package = "X::Colormap";
char *GContext_Package = "X::GContext";
char *KeySym_Package = "X::KeySym";
char *EventMask_Package = "X::Toolkit::EventMask";

char *Atom_Package = "X::Atom";
char *VisualID_Package = "X::VisualID";
char *Time_Package = "X::Time";
char *KeyCode_Package = "X::KeyCode";
char *XContext_Package = "X::Context";
char *Pixel_Package = "X::Pixel";

char *XrmQuark_Package = "X::Xrm::Quark";
char *XrmName_Package = "X::Xrm::Name";
char *XrmClass_Package = "X::Xrm::Class";
char *XrmRepresentation_Package = "X::Xrm::Representation";
char *XrmString_Package = "X::Xrm::String";
char *XrmDatabase_Package = "X::Xrm::Database";
char *XrmOptionDescRecPtr_Package = "X::Xrm::OptionDescRec";
char *XrmValuePtr_Package = "X::Xrm::Value";

char *DisplayPtr_Package = "X::Display";
char *GC_Package = "X::GC";
char *ScreenPtr_Package = "X::Screen";
char *VisualPtr_Package = "X::Visual";
char *XColorPtr_Package = "X::Color";
char *XGCValuesPtr_Package = "X::GCValues";
char *XHostAddressPtr_Package = "X::HostAddress";
char *XImagePtr_Package = "X::Image";
char *XArcPtr_Package = "X::Arc";
char *XChar2bPtr_Package = "X::Char2b";
char *XCharStructPtr_Package = "X::CharStruct";
char *XFontSet_Package = "X::FontSet";
char *XFontSetExtentsPtr_Package = "X::FontSetExtents";
char *XFontStructPtr_Package = "X::FontStruct";
char *XKeyboardControlPtr_Package = "X::KeyboardControl";
char *XKeyboardStatePtr_Package = "X::KeyboardState";
char *XModifierKeymapPtr_Package = "X::ModifierKeymap";
char *XPixmapFormatValuesPtr_Package = "X::PixmapFormatValues";
char *XPointPtr_Package = "X::Point";
char *XRectanglePtr_Package = "X::Rectangle";
char *XSegmentPtr_Package = "X::Segment";
char *XSetWindowAttributesPtr_Package = "X::SetWindowAttributes";
char *XTextItemPtr_Package = "X::TextItem";
char *XTextItem16Ptr_Package = "X::TextItem16";
char *XTimeCoordPtr_Package = "X::TimeCoord";
char *XWindowAttributesPtr_Package = "X::WindowAttributes";
char *XWindowChangesPtr_Package = "X::WindowChanges";
char *Region_Package = "X::Region";
char *XClassHintPtr_Package = "X::ClassHint";
char *XComposeStatusPtr_Package = "X::ComposeStatus";
char *XIconSizePtr_Package = "X::IconSize";
char *XSizeHintsPtr_Package = "X::SizeHints";
char *XStandardColormapPtr_Package = "X::StandardColormap";
char *XTextPropertyPtr_Package = "X::TextProperty";
char *XVisualInfoPtr_Package = "X::VisualInfo";
char *XWMHintsPtr_Package = "X::WMHints";

char *XKeyEventPtr_Package = "X::Event::KeyEvent";
char *XMappingEventPtr_Package = "X::Event::MappingEvent";
char *XButtonPressedEventPtr_Package = "X::Event::ButtonPressedEvent";
char *XSelectionRequestEventPtr_Package = "X::Event::SelectionRequestEvent";

char *XEventPtr_Package(int id) {
    switch (id) {
	case MotionNotify:
	     return "X::Event::MotionEvent";

	case ButtonPress:
	    return "X::Event::ButtonPressedEvent";

	case ButtonRelease:
	    return "X::Event::ButtonEvent";

	case ColormapNotify:
	    return "X::Event::ColormapEvent";

	case EnterNotify:
	case LeaveNotify:
	    return "X::Event::CrossingEvent";

	case Expose:
	    return "X::Event::ExposeEvent";

	case GraphicsExpose:
	    return "X::Event::GraphicsExposeEvent";

	case NoExpose:
	    return "X::Event::NoExposeEvent";

	case FocusIn:
	case FocusOut:
	    return "X::Event::FocusChangeEvent";

	case KeymapNotify:
	    return "X::Event::KeymapEvent";

	case KeyPress:
	case KeyRelease:
	    return "X::Event::KeyEvent";

	case PropertyNotify:
	    return "X::Event::PropertyEvent";

	case ResizeRequest:
	    return "X::Event::ResizeRequestEvent";

	case CirculateNotify:
	    return "X::Event::CirculateEvent";

	case ConfigureNotify:
	    return "X::Event::ConfigureEvent";

	case CreateNotify:
	    return "X::Event::CreateEvent";

	case DestroyNotify:
	    return "X::Event::DestroyEvent";

	case GravityNotify:
	    return "X::Event::GravityEvent";

	case MapNotify:
	    return "X::Event::MapEvent";

	case ReparentNotify:
	    return "X::Event::ReparentEvent";

	case UnmapNotify:
	    return "X::Event::UnmapEvent";

	case CirculateRequest:
	    return "X::Event::CirculateRequestEvent";

	case ConfigureRequest:
	    return "X::Event::ConfigureRequestEvent";

	case MapRequest:
	    return "X::Event::MapRequestEvent";

	case ClientMessage:
	    return "X::Event::ClientMessageEvent";

	case MappingNotify:
	    return "X::Event::MappingEvent";

	case SelectionClear:
	    return "X::Event::SelectionClearEvent";

	case SelectionNotify:
	    return "X::Event::SelectionEvent";

	case SelectionRequest:
	    return "X::Event::SelectionRequestEvent";

	case VisibilityNotify:
	    return "X::Event::VisibilityEvent";

	default:
	    return "X::Event";
    }
}

char *XtAppContext_Package = "X::Toolkit::Context";
char *WidgetClass_Package = "X::Toolkit::WidgetClass";
char *Widget_Package = "X::Toolkit::Widget";
char *XtInArg_Package = "X::Toolkit::InArg";
char *XtOutArg_Package = "X::Toolkit::OutArg";

char *Modifiers_Package = "X::Toolkit::Modifiers";
char *XtAccelerators_Package = "X::Toolkit::Accelerators";
char *XtTranslations_Package = "X::Toolkit::Translations";
char *XtWidgetGeometryPtr_Package = "X::Toolkit::WidgetGeometry";

char *XtActionHookId_Package = "X::Toolkit::ActionHookId";
char *XtInputId_Package = "X::Toolkit::InputId";
char *XtIntervalId_Package = "X::Toolkit::IntervalId";
char *XtRequestId_Package = "X::Toolkit::RequestId";
char *XtWorkProcId_Package = "X::Toolkit::WorkProcId";
