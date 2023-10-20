# vim:ft=xs

MODULE = X11::XCB PACKAGE = X11::XCB::ICCCM::WMHints

PROTOTYPES: ENABLE

X11_XCB_ICCCM_WMHints *
new(self)
    char *self
  PREINIT:
    X11_XCB_ICCCM_WMHints *buf;
  CODE:
    Newxz(buf, 1, X11_XCB_ICCCM_WMHints);
    RETVAL = buf;
  OUTPUT:
    RETVAL

MODULE = X11::XCB PACKAGE = X11_XCB_ICCCM_WMHintsPtr

void
set_flags(self, flags)
    X11_XCB_ICCCM_WMHints * self
    I32 flags
  CODE:
    self->flags = flags;

void
set_urgency(self)
    X11_XCB_ICCCM_WMHints * self
  CODE:
    #define XCB_ICCCM_WM_HINT_X_URGENCY (1L << 8)
    self->flags |= XCB_ICCCM_WM_HINT_X_URGENCY;

void
set_input(self, value)
    X11_XCB_ICCCM_WMHints * self
    uint32_t value
  CODE:
    #define XCB_ICCCM_WM_HINT_INPUT (1L << 0)
    self->flags |= XCB_ICCCM_WM_HINT_INPUT;
    self->input = value;

MODULE = X11::XCB PACKAGE = X11::XCB::ICCCM

void
set_wm_hints(conn, window, hints)
    XCBConnection * conn
    int window
    X11_XCB_ICCCM_WMHints * hints
  CODE:
    xcb_change_property(conn, XCB_PROP_MODE_REPLACE, window,
        XCB_ATOM_WM_HINTS, XCB_ATOM_WM_HINTS, 32,
	sizeof(*hints) >> 2, hints);

void
set_wm_size_hints(conn, window, property, hints)
    XCBConnection * conn
    int window
    int property
    X11_XCB_ICCCM_SizeHints * hints
  CODE:
    xcb_change_property(conn, XCB_PROP_MODE_REPLACE, window,
        property, XCB_ATOM_WM_SIZE_HINTS, 32, sizeof(*hints) >> 2, hints);




MODULE = X11::XCB PACKAGE = X11::XCB::ICCCM::SizeHints

PROTOTYPES: ENABLE

X11_XCB_ICCCM_SizeHints *
new(self)
    char *self
  PREINIT:
    X11_XCB_ICCCM_SizeHints *buf;
  CODE:
    Newxz(buf, 1, X11_XCB_ICCCM_SizeHints);
    RETVAL = buf;
  OUTPUT:
    RETVAL

MODULE = X11::XCB PACKAGE = X11_XCB_ICCCM_SizeHintsPtr

void
set_aspect(self, min_aspect_num, min_aspect_den, max_aspect_num, max_aspect_den)
    X11_XCB_ICCCM_SizeHints * self
    int min_aspect_num
    int min_aspect_den
    int max_aspect_num
    int max_aspect_den
  CODE:
    #define XCB_ICCCM_SIZE_HINT_P_ASPECT (1 << 7)
    self->flags |= XCB_ICCCM_SIZE_HINT_P_ASPECT;
    self->min_aspect_num = min_aspect_num;
    self->min_aspect_den = min_aspect_den;
    self->max_aspect_num = max_aspect_num;
    self->max_aspect_den = max_aspect_den;
