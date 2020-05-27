/*
 * This header defines the "C API" for this module.  It might be safe to copy
 * this header to other dists and use these functions, but I'm not making API
 * promises yet.
 */

typedef Display* DisplayOrNull; /* Used by typemap for stricter conversion */
typedef Visual* VisualOrNull;
typedef int ScreenNumber; /* used by typemap to coerce X11::Xlib::Screen */

/*--------------------------------------------------------
 * Functions to create/alter the magic Display* attached to X11::Xlib objects
 */

/* Get the Display* pointer (or NULL) for the given object. */
extern Display * PerlXlib_get_magic_dpy(SV *sv, Bool not_null);
/* Set the Display* pointer on X11::Xlib object and register that object association to that pointer */
extern SV * PerlXlib_set_magic_dpy(SV *sv, Display *dpy);
/* Get the X11::Xlib object of a Display*, possibly creating a new perl object for it if not registered.
 * The returned SV* does not need to be released/freed. (already mortal, or ref to hash element) */
extern SV * PerlXlib_obj_for_display(Display *dpy, int create);

/* un-pack an XID from a wrapped X11::Xlib::XID or subclass */
extern XID PerlXlib_sv_to_xid(SV *sv);

/*---------------------------------------------------------
 * Functions to wrap/unwrap opaque X11 pointers to/from objects
 */

/* Return the "generic xlib pointer" attached (via magic) to the object. */
extern void * PerlXlib_sv_to_display_innerptr(SV *sv, bool not_null);
/* Return the inflated object for the given pointer.  Object is cached in X11::Xlib instance for *dpy.
 * Returned SV does not need to be released/freed. (already mortal, or ref to hash element) */
extern SV * PerlXlib_obj_for_display_innerptr(Display *dpy, void *thing, const char *thing_class, int svtype, bool create);
/* Same as PerlXlib_sv_to_display_innerptr, for when the object is a hashref and pointer is attached via magic */
extern void * PerlXlib_get_magic_dpy_innerptr(SV *sv, Bool not_null);
/* Same as PerlXlib_obj_for_display_innerptr, for when the object is a hashref and pointer is attached via magic */
extern SV * PerlXlib_set_magic_dpy_innerptr(SV *sv, void *innerptr);
/* Same as PerlXlib_sv_to_display_innerptr, but Screen* is special */
extern Screen * PerlXlib_sv_to_screen(SV *sv, bool not_null);
/* Same as PerlXlib_obj_for_display_innerptr, but Screen* is special */
extern SV * PerlXlib_obj_for_screen(Screen *screen);

/*-----------------------------------------------------------
 * Generically add ->display attribute to any pointer-based object.
 * These are tracked inside-out style from a private hash, requiring
 * destructor support to clean up.
 */
extern SV * PerlXlib_get_displayobj_of_opaque(void *thing);
extern void PerlXlib_set_displayobj_of_opaque(void *thing, SV *dpy_sv);

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

/* Keysym/unicode utility functions */
extern int PerlXlib_keysym_to_codepoint(KeySym keysym);
extern KeySym PerlXlib_codepoint_to_keysym(int codepoint);
extern SV * PerlXlib_keysym_to_sv(KeySym keysym, int symbolic);
extern KeySym PerlXlib_sv_to_keysym(SV *sv);

extern void PerlXlib_install_error_handlers(Bool nonfatal, Bool fatal);
