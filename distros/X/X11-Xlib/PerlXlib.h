/*
 * This header defines the "C API" for this module.  It might be safe to copy
 * this header to other dists and use these functions, but I'm not making API
 * promises yet.
 */

typedef Display* DisplayOrNull; /* Used by typemap for stricter conversion */
typedef Visual* VisualOrNull;
typedef Window WindowOrNull;
typedef int ScreenNumber; /* used by typemap to coerce X11::Xlib::Screen */

#define PerlXlib_OR_NULL    0
#define PerlXlib_OR_UNDEF   1
#define PerlXlib_OR_DIE     2
#define PerlXlib_AUTOCREATE 3

/* lookup or create a wrapper around a pointer */
extern SV * PerlXlib_get_objref(void *thing, int create_flag,
    const char *thing_type, int obj_svtype, const char *thing_class, void *parent);
/* get the pointer wrapped by an object */
extern void * PerlXlib_objref_get_pointer(SV *objref, const char *ptr_type, int fail_flag);
/* set the pointer wrapped by an object */
extern void PerlXlib_objref_set_pointer(SV *objref, void *pointer, const char *ptr_type);

/* Special cases for wrap/get/set Display* on a X11::Xlib instance */
extern SV * PerlXlib_get_display_objref(Display *dpy, int create_flag);
extern Display * PerlXlib_display_objref_get_pointer(SV *displayref, int fail_flag);

/* unpack an XID from a wrapped X11::Xlib::XID or subclass */
extern XID PerlXlib_sv_to_xid(SV *sv);

/*---------------------------------------------------------
 * Accessor for $obj->display attribute
 */
extern SV * PerlXlib_objref_get_display(SV *obj);
extern void PerlXlib_objref_set_display(SV *obj, SV *displayref);

/*---------------------------------------------------------
 * Functions to wrap/unwrap opaque X11 pointers to/from objects
 */

/* Same as PerlXlib_sv_to_display_innerptr, but Screen* is special */
extern Screen * PerlXlib_screen_objref_get_pointer(SV *sv, int fail_flag);
/* Same as PerlXlib_obj_for_display_innerptr, but Screen* is special */
extern SV * PerlXlib_get_screen_objref(Screen *screen, int create_flag);

/*-----------------------------------------------------------
 * Functions to pack/unpack structs into blessed scalars.
 *
 * _pack functions read perl fields from a hashref and write to
 *       the fields of a C struct.
 * _unpack functions take the fields of a C struct and inflate them
 *         to Perl SV or objects and store them into a hashref.
 * _unpack_obj functions are the same as _unpack but also pass a
 *             reference (RV) to the object being unpacked.  This is
 *             needed in some cases to see the ->display attribute.
 * _unpack_obj makes _unpack obsolete, but the _unpack still need to
 * be exported to maintain the previous public C API.
 */
typedef void PerlXlib_struct_pack_fn(void*, HV*, Bool consume);
extern void* PerlXlib_get_struct_ptr(SV *sv, int lvalue, const char* pkg, int struct_size, PerlXlib_struct_pack_fn *packer);
extern const char* PerlXlib_xevent_pkg_for_type(int type);
extern void PerlXlib_XEvent_pack(XEvent *s, HV *fields, Bool consume);
extern void PerlXlib_XEvent_unpack(XEvent *s, HV *fields);
extern void PerlXlib_XVisualInfo_pack(XVisualInfo *s, HV *fields, Bool consume);
extern void PerlXlib_XVisualInfo_unpack(XVisualInfo *s, HV *fields);
extern void PerlXlib_XVisualInfo_unpack_obj(XVisualInfo *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XWindowAttributes_pack(XWindowAttributes *s, HV *fields, Bool consume);
extern void PerlXlib_XWindowAttributes_unpack(XWindowAttributes *s, HV *fields);
extern void PerlXlib_XWindowAttributes_unpack_obj(XWindowAttributes *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XSetWindowAttributes_pack(XSetWindowAttributes *s, HV *fields, Bool consume);
extern void PerlXlib_XSetWindowAttributes_unpack(XSetWindowAttributes *s, HV *fields);
extern void PerlXlib_XSetWindowAttributes_unpack_obj(XSetWindowAttributes *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XWindowChanges_pack(XWindowChanges *s, HV *fields, Bool consume);
extern void PerlXlib_XWindowChanges_unpack(XWindowChanges *s, HV *fields);
extern void PerlXlib_XWindowChanges_unpack_obj(XWindowChanges *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XSizeHints_pack(XSizeHints *s, HV *fields, Bool consume);
extern void PerlXlib_XSizeHints_unpack(XSizeHints *s, HV *fields);
extern void PerlXlib_XSizeHints_unpack_obj(XSizeHints *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XKeyboardState_pack(XKeyboardState *s, HV *fields, Bool consume);
extern void PerlXlib_XKeyboardState_unpack(XKeyboardState *s, HV *fields);
extern void PerlXlib_XKeyboardState_unpack_obj(XKeyboardState *s, HV *fields, SV *obj_ref);
extern void PerlXlib_XRectangle_pack(XRectangle *s, HV *fields, Bool consume);
extern void PerlXlib_XRectangle_unpack(XRectangle *s, HV *fields);
extern void PerlXlib_XRectangle_unpack_obj(XRectangle *s, HV *fields, SV *obj_ref);
#ifndef HAVE_XRENDER
/* Copied from X11/extensions/Xrender.h because I decided it was better to define the struct
   than to have the perl interface change depending on whether it found a header file or not.
   (imagine, installing this module when Xrender.h was not found but then installing a
    dependent module after Xrender.h was installed)
*/
typedef XID PictFormat;
typedef struct {
    short   red;
    short   redMask;
    short   green;
    short   greenMask;
    short   blue;
    short   blueMask;
    short   alpha;
    short   alphaMask;
} XRenderDirectFormat;
typedef struct {
    PictFormat          id;
    int                 type;
    int                 depth;
    XRenderDirectFormat direct;
    Colormap            colormap;
} XRenderPictFormat;
#endif
extern void PerlXlib_XRenderPictFormat_pack(XRenderPictFormat *s, HV *fields, Bool consume);
extern void PerlXlib_XRenderPictFormat_unpack(XRenderPictFormat *s, HV *fields);
extern void PerlXlib_XRenderPictFormat_unpack_obj(XRenderPictFormat *s, HV *fields, SV *obj_ref);

/* Keysym/Unicode utility functions */
extern int PerlXlib_keysym_to_codepoint(KeySym keysym);
extern KeySym PerlXlib_codepoint_to_keysym(int codepoint);
extern SV * PerlXlib_keysym_to_sv(KeySym keysym, int symbolic);
extern KeySym PerlXlib_sv_to_keysym(SV *sv);

extern void PerlXlib_install_error_handlers(Bool nonfatal, Bool fatal);

/* Back-compat, deprecated */
extern Display * PerlXlib_get_magic_dpy(SV *sv, Bool not_null);
extern SV * PerlXlib_set_magic_dpy(SV *sv, Display *dpy);
extern SV * PerlXlib_obj_for_display(Display *dpy, int create);
extern void * PerlXlib_sv_to_display_innerptr(SV *sv, bool not_null);
extern SV * PerlXlib_obj_for_display_innerptr(Display *dpy, void *thing, const char *thing_class, int obj_svtype, bool create);
extern void * PerlXlib_get_magic_dpy_innerptr(SV *sv, Bool not_null);
extern SV * PerlXlib_set_magic_dpy_innerptr(SV *sv, void *innerptr);
extern SV * PerlXlib_get_displayobj_of_opaque(void *thing);
extern void PerlXlib_set_displayobj_of_opaque(void *thing, SV *dpy_sv);
extern SV * PerlXlib_obj_for_screen(Screen *screen);
extern Screen * PerlXlib_sv_to_screen(SV *sv, bool not_null);
