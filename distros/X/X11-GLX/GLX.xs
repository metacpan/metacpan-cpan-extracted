#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <GL/glx.h>
#include <GL/glxext.h>
#include "PerlXlib.h"

extern GLXContextID glXGetContextIDEXT(GLXContext cx);
extern Bool glXQueryContextInfoEXT(Display *dpy, GLXContext cx, int attr, int *out_val);
extern GLXContext glXImportContextEXT(Display *dpy, GLXContextID id);
extern void glXFreeContextEXT(Display *dpy, GLXContext cx);

typedef GLXContext GLXContextOrNull;
typedef GLXContext GLXContextImported;

MODULE = X11::GLX                  PACKAGE = X11::GLX

void
_const_unavailable()
	PPCODE:
		croak("Symbol not avilable on this version of GLX");

# Standard GLX Functions (fn_std) --------------------------------------------

Bool
glXQueryVersion(dpy, major, minor)
	Display *dpy
	SV *major
	SV *minor
	INIT:
		int vmajor, vminor;
	CODE:
		RETVAL = glXQueryVersion(dpy, &vmajor, &vminor);
		if (RETVAL) { sv_setiv(major, vmajor); sv_setiv(minor, vminor); }
	OUTPUT:
		RETVAL

const char *
glXQueryExtensionsString(dpy, screen=DefaultScreen(dpy))
	Display *dpy
	int screen

void
glXChooseVisual(dpy, screen=DefaultScreen(dpy), attrs=NULL)
	Display *dpy
	int screen
	SV *attrs
	INIT:
		SV *tmp, **ep, *vis_sv, *dpy_sv;
		AV *attr_av;
		HV *attr_hv;
		int i, n, *attr_array;
		XVisualInfo *match;
		int default_attrs[] = {
			GLX_USE_GL, GLX_RGBA,
			GLX_RED_SIZE, 8, GLX_GREEN_SIZE, 8, GLX_BLUE_SIZE, 8, GLX_ALPHA_SIZE, 8,
			GLX_DOUBLEBUFFER, None
		};
	PPCODE:
		dpy_sv= ST(0);
		if (!attrs || !SvOK(attrs)) {
			match= glXChooseVisual(dpy, screen, default_attrs);
		}
		else if (SvROK(attrs) && (SvTYPE(attrs) == SVt_PVAV)) {
			attr_av= (AV*) SvRV(attrs);
			n= av_len(attr_av)+1;
			Newx(attr_array, n+1, int);
			SAVEFREEPV(attr_array);
			for (i= 0; i < n; i++) {
				ep= av_fetch(attr_av, i, 0);
				if (!ep || !*ep) croak("Can't access attrib %d", i);
				attr_array[i]= SvIV(*ep);
			}
			attr_array[n]= None;
			match= glXChooseVisual(dpy, screen, attr_array);
		}
		if (match) {
			vis_sv= sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", (void*)match, sizeof(XVisualInfo));
			PUSHs(sv_2mortal(vis_sv));
			XFree(match);
			PerlXlib_objref_set_display(vis_sv, dpy_sv);
		}

#ifdef GLX_VERSION_1_3

void
glXChooseFBConfig(dpy, screen, attr_av)
	Display *dpy
	ScreenNumber screen
	AV *attr_av
	INIT:
		int *attr_array;
		int i, n_elem;
		SV **elem, *dpy_sv, *fb;
		GLXFBConfig *cfgs;
	PPCODE:
		dpy_sv= ST(0);
		/* Re-package attr_av into int[] */
		n_elem= av_len(attr_av)+1;
		Newx(attr_array, n_elem+1, int);
		SAVEFREEPV(attr_array);
		for (i= 0; i < n_elem; i++) {
			elem= av_fetch(attr_av, i, 0);
			if (!elem || !*elem) croak("Can't access attrib %d", i);
			attr_array[i]= SvIV(*elem);
		}
		attr_array[n_elem]= None; /* in case user didn't 'None'-terminate the list */
		cfgs= glXChooseFBConfig(dpy, screen, attr_array, &n_elem);
		if (cfgs) {
			EXTEND(SP, n_elem);
			for (i= 0; i < n_elem; i++)
				PUSHs(PerlXlib_get_objref(cfgs[i], PerlXlib_AUTOCREATE, "GLXFBConfig", SVt_PVHV, "X11::GLX::FBConfig", dpy));
			XFree(cfgs);
		}

void
glXGetFBConfigs(dpy, screen= -1)
	Display *dpy
	ScreenNumber screen
	INIT:
		GLXFBConfig *cfgs;
		int n_elem, i;
		SV *fb;
	PPCODE:
		cfgs= glXGetFBConfigs(dpy, screen, &n_elem);
		if (cfgs) {
			EXTEND(SP, n_elem);
			for (i= 0; i < n_elem; i++)
				PUSHs(PerlXlib_get_objref(cfgs[i], PerlXlib_AUTOCREATE, "GLXFBConfig", SVt_PVHV, "X11::GLX::FBConfig", dpy));
			/* no indication in docs that we should free cfg ... */
		}

int
glXGetFBConfigAttrib(dpy, fbcfg, attr, value_sv)
	Display *dpy
	GLXFBConfig fbcfg
	int attr
	SV *value_sv
	INIT:
		int value;
	CODE:
		RETVAL= glXGetFBConfigAttrib(dpy, fbcfg, attr, &value);
		if (RETVAL == Success)
			sv_setiv(value_sv, value);
	OUTPUT:
		RETVAL

void
glXGetVisualFromFBConfig(dpy, fbcfg)
	Display *dpy
	GLXFBConfig fbcfg
	INIT:
		XVisualInfo *vis;
		SV *dpy_sv, *vis_sv;
	PPCODE:
		dpy_sv= ST(0);
		vis= glXGetVisualFromFBConfig(dpy, fbcfg);
		if (vis) {
			vis_sv= sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", (void*) vis, sizeof(XVisualInfo));
			PUSHs(sv_2mortal(vis_sv));
			XFree(vis);
			PerlXlib_objref_set_display(vis_sv, dpy_sv);
		}

GLXContext
glXCreateNewContext(dpy, fbcfg, render_type, shared, direct)
	Display *dpy
	GLXFBConfig fbcfg
	int render_type
	GLXContextOrNull shared
	Bool direct

#endif /* GLX_VERSION_1_3 */

GLXContext
glXCreateContext(dpy, vis_info, shared, direct)
	Display *dpy
	XVisualInfo *vis_info
	GLXContextOrNull shared
	Bool direct

void
glXDestroyContext(dpy, cx)
	Display *dpy
	GLXContext cx
	INIT:
		SV *cx_sv= ST(1);
	CODE:
		glXDestroyContext(dpy, cx);
		/* Now, null the pointer to mark it as being properly freed */
		PerlXlib_objref_set_pointer(cx_sv, NULL, NULL);

Bool
glXMakeCurrent(dpy, xid= None, cx= NULL)
	Display *dpy
	Drawable xid
	GLXContext cx

# Create a GLXPixmap, which is an XPixmap with special extra buffers needed
# for rendering.  Thanks to the wonderful X11 documentation for not mentioning
# that you can't just pass a regular XPixmap to glXMakeCurrent, and wasting
# half my day.
Pixmap
glXCreateGLXPixmap(dpy, vis_info, xpmap)
	Display *dpy
	XVisualInfo *vis_info
	Pixmap xpmap

void
glXDestroyGLXPixmap(dpy, xid)
	Display *dpy
	Pixmap xid

void
glXSwapBuffers(dpy, cx)
	Display *dpy
	Drawable cx

# Extension GLX_EXT_import_context (fn_import_cx) ----------------------------

GLXContextID
glXGetContextIDEXT(cx)
	GLXContext cx

GLXContextImported
glXImportContextEXT(dpy, cx_id)
	Display *dpy
	GLXContextID cx_id

void
glXFreeContextEXT(dpy, cx)
	Display *dpy
	GLXContextImported cx
	INIT:
		SV *cx_sv= ST(1);
	CODE:
		glXFreeContextEXT(dpy, cx);
		/* Now, null the pointer to mark it as being properly freed */
		PerlXlib_objref_set_pointer(cx_sv, NULL, NULL);

int
glXQueryContextInfoEXT(dpy, cx, attr_id, val_out_sv)
	Display *dpy
	GLXContext cx
	int attr_id
	SV *val_out_sv
	INIT:
		int val_out;
	CODE:
		RETVAL = glXQueryContextInfoEXT(dpy, cx, attr_id, &val_out);
		if (RETVAL == Success)
			sv_setiv(val_out_sv, val_out);
	OUTPUT:
		RETVAL


MODULE = X11::GLX                     PACKAGE = X11::GLX::Context

GLXContextID
id(self)
	GLXContext self
	CODE:
		RETVAL = glXGetContextIDEXT(self);
	OUTPUT:
		RETVAL

bool
_already_freed(cx)
	GLXContextOrNull cx
	CODE:
		RETVAL = !cx;
	OUTPUT:
		RETVAL

MODULE = X11::GLX                     PACKAGE = X11::GLX::DWIM

int
_build_gl_clear_bits(self)
	SV *self
	CODE:
		RETVAL = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT;
	OUTPUT:
		RETVAL

void
_glClear(bits)
	int bits
	CODE:
		glClear(bits);

void
_glFlush()
	CODE:
		glFlush();

int
_glGetError()
	CODE:
		RETVAL = glGetError();
	OUTPUT:
		RETVAL

void
_set_blank_cursor(dpy, wnd)
	Display *dpy
	Window wnd
	CODE:
		XColor black;
		static char noData[] = { 0,0,0,0,0,0,0,0 };
		Pixmap bitmapNoData;
		Cursor invisibleCursor;

		black.red = black.green = black.blue = 0;
		bitmapNoData= XCreateBitmapFromData(dpy, wnd, noData, 8, 8);
		if (!bitmapNoData)
			croak("XCreateBitmapFromData failed");
		invisibleCursor= XCreatePixmapCursor(dpy, bitmapNoData, bitmapNoData, &black, &black, 0, 0);
		XFreePixmap(dpy, bitmapNoData);
		if (!invisibleCursor)
			croak("XCreatePixmapCursor failed");
		XDefineCursor(dpy, wnd, invisibleCursor);
		XFreeCursor(dpy, invisibleCursor);

void
_set_projection_matrix(is_frustum, left, right, bottom, top, near, far, x, y, z, mirror_x, mirror_y)
	int is_frustum
	double left
	double right
	double bottom
	double top
	double near
	double far
	double x
	double y
	double z
	int mirror_x
	int mirror_y
	CODE:
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		if (is_frustum) glFrustum(left, right, bottom, top, near, far);
		else glOrtho(left, right, bottom, top, near, far);
		
		if (x || y || z) glTranslated(-x, -y, -z);
	
		/* If mirror is in effect, need to tell OpenGL which way the camera is */
		glFrontFace(mirror_x == mirror_y? GL_CCW : GL_CW);
		glMatrixMode(GL_MODELVIEW);

BOOT:
# BEGIN GENERATED BOOT CONSTANTS
  HV* stash= gv_stashpvn("X11::GLX", 8, 1);
#ifdef GLX_USE_GL
  newCONSTSUB(stash, "GLX_USE_GL", newSViv(GLX_USE_GL));
#else
  newXS("X11::GLX::GLX_USE_GL", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BUFFER_SIZE
  newCONSTSUB(stash, "GLX_BUFFER_SIZE", newSViv(GLX_BUFFER_SIZE));
#else
  newXS("X11::GLX::GLX_BUFFER_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_LEVEL
  newCONSTSUB(stash, "GLX_LEVEL", newSViv(GLX_LEVEL));
#else
  newXS("X11::GLX::GLX_LEVEL", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RGBA
  newCONSTSUB(stash, "GLX_RGBA", newSViv(GLX_RGBA));
#else
  newXS("X11::GLX::GLX_RGBA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DOUBLEBUFFER
  newCONSTSUB(stash, "GLX_DOUBLEBUFFER", newSViv(GLX_DOUBLEBUFFER));
#else
  newXS("X11::GLX::GLX_DOUBLEBUFFER", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_STEREO
  newCONSTSUB(stash, "GLX_STEREO", newSViv(GLX_STEREO));
#else
  newXS("X11::GLX::GLX_STEREO", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX_BUFFERS
  newCONSTSUB(stash, "GLX_AUX_BUFFERS", newSViv(GLX_AUX_BUFFERS));
#else
  newXS("X11::GLX::GLX_AUX_BUFFERS", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RED_SIZE
  newCONSTSUB(stash, "GLX_RED_SIZE", newSViv(GLX_RED_SIZE));
#else
  newXS("X11::GLX::GLX_RED_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_GREEN_SIZE
  newCONSTSUB(stash, "GLX_GREEN_SIZE", newSViv(GLX_GREEN_SIZE));
#else
  newXS("X11::GLX::GLX_GREEN_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BLUE_SIZE
  newCONSTSUB(stash, "GLX_BLUE_SIZE", newSViv(GLX_BLUE_SIZE));
#else
  newXS("X11::GLX::GLX_BLUE_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ALPHA_SIZE
  newCONSTSUB(stash, "GLX_ALPHA_SIZE", newSViv(GLX_ALPHA_SIZE));
#else
  newXS("X11::GLX::GLX_ALPHA_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DEPTH_SIZE
  newCONSTSUB(stash, "GLX_DEPTH_SIZE", newSViv(GLX_DEPTH_SIZE));
#else
  newXS("X11::GLX::GLX_DEPTH_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_STENCIL_SIZE
  newCONSTSUB(stash, "GLX_STENCIL_SIZE", newSViv(GLX_STENCIL_SIZE));
#else
  newXS("X11::GLX::GLX_STENCIL_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ACCUM_RED_SIZE
  newCONSTSUB(stash, "GLX_ACCUM_RED_SIZE", newSViv(GLX_ACCUM_RED_SIZE));
#else
  newXS("X11::GLX::GLX_ACCUM_RED_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ACCUM_GREEN_SIZE
  newCONSTSUB(stash, "GLX_ACCUM_GREEN_SIZE", newSViv(GLX_ACCUM_GREEN_SIZE));
#else
  newXS("X11::GLX::GLX_ACCUM_GREEN_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ACCUM_BLUE_SIZE
  newCONSTSUB(stash, "GLX_ACCUM_BLUE_SIZE", newSViv(GLX_ACCUM_BLUE_SIZE));
#else
  newXS("X11::GLX::GLX_ACCUM_BLUE_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ACCUM_ALPHA_SIZE
  newCONSTSUB(stash, "GLX_ACCUM_ALPHA_SIZE", newSViv(GLX_ACCUM_ALPHA_SIZE));
#else
  newXS("X11::GLX::GLX_ACCUM_ALPHA_SIZE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_SCREEN
  newCONSTSUB(stash, "GLX_BAD_SCREEN", newSViv(GLX_BAD_SCREEN));
#else
  newXS("X11::GLX::GLX_BAD_SCREEN", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_ATTRIBUTE
  newCONSTSUB(stash, "GLX_BAD_ATTRIBUTE", newSViv(GLX_BAD_ATTRIBUTE));
#else
  newXS("X11::GLX::GLX_BAD_ATTRIBUTE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_NO_EXTENSION
  newCONSTSUB(stash, "GLX_NO_EXTENSION", newSViv(GLX_NO_EXTENSION));
#else
  newXS("X11::GLX::GLX_NO_EXTENSION", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_VISUAL
  newCONSTSUB(stash, "GLX_BAD_VISUAL", newSViv(GLX_BAD_VISUAL));
#else
  newXS("X11::GLX::GLX_BAD_VISUAL", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_CONTEXT
  newCONSTSUB(stash, "GLX_BAD_CONTEXT", newSViv(GLX_BAD_CONTEXT));
#else
  newXS("X11::GLX::GLX_BAD_CONTEXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_VALUE
  newCONSTSUB(stash, "GLX_BAD_VALUE", newSViv(GLX_BAD_VALUE));
#else
  newXS("X11::GLX::GLX_BAD_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BAD_ENUM
  newCONSTSUB(stash, "GLX_BAD_ENUM", newSViv(GLX_BAD_ENUM));
#else
  newXS("X11::GLX::GLX_BAD_ENUM", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_VENDOR
  newCONSTSUB(stash, "GLX_VENDOR", newSViv(GLX_VENDOR));
#else
  newXS("X11::GLX::GLX_VENDOR", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_VERSION
  newCONSTSUB(stash, "GLX_VERSION", newSViv(GLX_VERSION));
#else
  newXS("X11::GLX::GLX_VERSION", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_EXTENSIONS
  newCONSTSUB(stash, "GLX_EXTENSIONS", newSViv(GLX_EXTENSIONS));
#else
  newXS("X11::GLX::GLX_EXTENSIONS", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_CONFIG_CAVEAT
  newCONSTSUB(stash, "GLX_CONFIG_CAVEAT", newSViv(GLX_CONFIG_CAVEAT));
#else
  newXS("X11::GLX::GLX_CONFIG_CAVEAT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DONT_CARE
  newCONSTSUB(stash, "GLX_DONT_CARE", newSViv(GLX_DONT_CARE));
#else
  newXS("X11::GLX::GLX_DONT_CARE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_X_VISUAL_TYPE
  newCONSTSUB(stash, "GLX_X_VISUAL_TYPE", newSViv(GLX_X_VISUAL_TYPE));
#else
  newXS("X11::GLX::GLX_X_VISUAL_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_TYPE
  newCONSTSUB(stash, "GLX_TRANSPARENT_TYPE", newSViv(GLX_TRANSPARENT_TYPE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_INDEX_VALUE
  newCONSTSUB(stash, "GLX_TRANSPARENT_INDEX_VALUE", newSViv(GLX_TRANSPARENT_INDEX_VALUE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_INDEX_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_RED_VALUE
  newCONSTSUB(stash, "GLX_TRANSPARENT_RED_VALUE", newSViv(GLX_TRANSPARENT_RED_VALUE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_RED_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_GREEN_VALUE
  newCONSTSUB(stash, "GLX_TRANSPARENT_GREEN_VALUE", newSViv(GLX_TRANSPARENT_GREEN_VALUE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_GREEN_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_BLUE_VALUE
  newCONSTSUB(stash, "GLX_TRANSPARENT_BLUE_VALUE", newSViv(GLX_TRANSPARENT_BLUE_VALUE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_BLUE_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_ALPHA_VALUE
  newCONSTSUB(stash, "GLX_TRANSPARENT_ALPHA_VALUE", newSViv(GLX_TRANSPARENT_ALPHA_VALUE));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_ALPHA_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_WINDOW_BIT
  newCONSTSUB(stash, "GLX_WINDOW_BIT", newSViv(GLX_WINDOW_BIT));
#else
  newXS("X11::GLX::GLX_WINDOW_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PIXMAP_BIT
  newCONSTSUB(stash, "GLX_PIXMAP_BIT", newSViv(GLX_PIXMAP_BIT));
#else
  newXS("X11::GLX::GLX_PIXMAP_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PBUFFER_BIT
  newCONSTSUB(stash, "GLX_PBUFFER_BIT", newSViv(GLX_PBUFFER_BIT));
#else
  newXS("X11::GLX::GLX_PBUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX_BUFFERS_BIT
  newCONSTSUB(stash, "GLX_AUX_BUFFERS_BIT", newSViv(GLX_AUX_BUFFERS_BIT));
#else
  newXS("X11::GLX::GLX_AUX_BUFFERS_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FRONT_LEFT_BUFFER_BIT
  newCONSTSUB(stash, "GLX_FRONT_LEFT_BUFFER_BIT", newSViv(GLX_FRONT_LEFT_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_FRONT_LEFT_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FRONT_RIGHT_BUFFER_BIT
  newCONSTSUB(stash, "GLX_FRONT_RIGHT_BUFFER_BIT", newSViv(GLX_FRONT_RIGHT_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_FRONT_RIGHT_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BACK_LEFT_BUFFER_BIT
  newCONSTSUB(stash, "GLX_BACK_LEFT_BUFFER_BIT", newSViv(GLX_BACK_LEFT_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_BACK_LEFT_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BACK_RIGHT_BUFFER_BIT
  newCONSTSUB(stash, "GLX_BACK_RIGHT_BUFFER_BIT", newSViv(GLX_BACK_RIGHT_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_BACK_RIGHT_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DEPTH_BUFFER_BIT
  newCONSTSUB(stash, "GLX_DEPTH_BUFFER_BIT", newSViv(GLX_DEPTH_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_DEPTH_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_STENCIL_BUFFER_BIT
  newCONSTSUB(stash, "GLX_STENCIL_BUFFER_BIT", newSViv(GLX_STENCIL_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_STENCIL_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_ACCUM_BUFFER_BIT
  newCONSTSUB(stash, "GLX_ACCUM_BUFFER_BIT", newSViv(GLX_ACCUM_BUFFER_BIT));
#else
  newXS("X11::GLX::GLX_ACCUM_BUFFER_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_NONE
  newCONSTSUB(stash, "GLX_NONE", newSViv(GLX_NONE));
#else
  newXS("X11::GLX::GLX_NONE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SLOW_CONFIG
  newCONSTSUB(stash, "GLX_SLOW_CONFIG", newSViv(GLX_SLOW_CONFIG));
#else
  newXS("X11::GLX::GLX_SLOW_CONFIG", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRUE_COLOR
  newCONSTSUB(stash, "GLX_TRUE_COLOR", newSViv(GLX_TRUE_COLOR));
#else
  newXS("X11::GLX::GLX_TRUE_COLOR", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DIRECT_COLOR
  newCONSTSUB(stash, "GLX_DIRECT_COLOR", newSViv(GLX_DIRECT_COLOR));
#else
  newXS("X11::GLX::GLX_DIRECT_COLOR", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PSEUDO_COLOR
  newCONSTSUB(stash, "GLX_PSEUDO_COLOR", newSViv(GLX_PSEUDO_COLOR));
#else
  newXS("X11::GLX::GLX_PSEUDO_COLOR", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_STATIC_COLOR
  newCONSTSUB(stash, "GLX_STATIC_COLOR", newSViv(GLX_STATIC_COLOR));
#else
  newXS("X11::GLX::GLX_STATIC_COLOR", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_GRAY_SCALE
  newCONSTSUB(stash, "GLX_GRAY_SCALE", newSViv(GLX_GRAY_SCALE));
#else
  newXS("X11::GLX::GLX_GRAY_SCALE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_STATIC_GRAY
  newCONSTSUB(stash, "GLX_STATIC_GRAY", newSViv(GLX_STATIC_GRAY));
#else
  newXS("X11::GLX::GLX_STATIC_GRAY", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_RGB
  newCONSTSUB(stash, "GLX_TRANSPARENT_RGB", newSViv(GLX_TRANSPARENT_RGB));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_RGB", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TRANSPARENT_INDEX
  newCONSTSUB(stash, "GLX_TRANSPARENT_INDEX", newSViv(GLX_TRANSPARENT_INDEX));
#else
  newXS("X11::GLX::GLX_TRANSPARENT_INDEX", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_VISUAL_ID
  newCONSTSUB(stash, "GLX_VISUAL_ID", newSViv(GLX_VISUAL_ID));
#else
  newXS("X11::GLX::GLX_VISUAL_ID", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SCREEN
  newCONSTSUB(stash, "GLX_SCREEN", newSViv(GLX_SCREEN));
#else
  newXS("X11::GLX::GLX_SCREEN", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_VISUAL_ID_EXT
  newCONSTSUB(stash, "GLX_VISUAL_ID_EXT", newSViv(GLX_VISUAL_ID_EXT));
#else
  newXS("X11::GLX::GLX_VISUAL_ID_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SCREEN_EXT
  newCONSTSUB(stash, "GLX_SCREEN_EXT", newSViv(GLX_SCREEN_EXT));
#else
  newXS("X11::GLX::GLX_SCREEN_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_NON_CONFORMANT_CONFIG
  newCONSTSUB(stash, "GLX_NON_CONFORMANT_CONFIG", newSViv(GLX_NON_CONFORMANT_CONFIG));
#else
  newXS("X11::GLX::GLX_NON_CONFORMANT_CONFIG", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DRAWABLE_TYPE
  newCONSTSUB(stash, "GLX_DRAWABLE_TYPE", newSViv(GLX_DRAWABLE_TYPE));
#else
  newXS("X11::GLX::GLX_DRAWABLE_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDER_TYPE
  newCONSTSUB(stash, "GLX_RENDER_TYPE", newSViv(GLX_RENDER_TYPE));
#else
  newXS("X11::GLX::GLX_RENDER_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_X_RENDERABLE
  newCONSTSUB(stash, "GLX_X_RENDERABLE", newSViv(GLX_X_RENDERABLE));
#else
  newXS("X11::GLX::GLX_X_RENDERABLE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FBCONFIG_ID
  newCONSTSUB(stash, "GLX_FBCONFIG_ID", newSViv(GLX_FBCONFIG_ID));
#else
  newXS("X11::GLX::GLX_FBCONFIG_ID", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RGBA_TYPE
  newCONSTSUB(stash, "GLX_RGBA_TYPE", newSViv(GLX_RGBA_TYPE));
#else
  newXS("X11::GLX::GLX_RGBA_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_COLOR_INDEX_TYPE
  newCONSTSUB(stash, "GLX_COLOR_INDEX_TYPE", newSViv(GLX_COLOR_INDEX_TYPE));
#else
  newXS("X11::GLX::GLX_COLOR_INDEX_TYPE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_MAX_PBUFFER_WIDTH
  newCONSTSUB(stash, "GLX_MAX_PBUFFER_WIDTH", newSViv(GLX_MAX_PBUFFER_WIDTH));
#else
  newXS("X11::GLX::GLX_MAX_PBUFFER_WIDTH", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_MAX_PBUFFER_HEIGHT
  newCONSTSUB(stash, "GLX_MAX_PBUFFER_HEIGHT", newSViv(GLX_MAX_PBUFFER_HEIGHT));
#else
  newXS("X11::GLX::GLX_MAX_PBUFFER_HEIGHT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_MAX_PBUFFER_PIXELS
  newCONSTSUB(stash, "GLX_MAX_PBUFFER_PIXELS", newSViv(GLX_MAX_PBUFFER_PIXELS));
#else
  newXS("X11::GLX::GLX_MAX_PBUFFER_PIXELS", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PRESERVED_CONTENTS
  newCONSTSUB(stash, "GLX_PRESERVED_CONTENTS", newSViv(GLX_PRESERVED_CONTENTS));
#else
  newXS("X11::GLX::GLX_PRESERVED_CONTENTS", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_LARGEST_PBUFFER
  newCONSTSUB(stash, "GLX_LARGEST_PBUFFER", newSViv(GLX_LARGEST_PBUFFER));
#else
  newXS("X11::GLX::GLX_LARGEST_PBUFFER", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_WIDTH
  newCONSTSUB(stash, "GLX_WIDTH", newSViv(GLX_WIDTH));
#else
  newXS("X11::GLX::GLX_WIDTH", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_HEIGHT
  newCONSTSUB(stash, "GLX_HEIGHT", newSViv(GLX_HEIGHT));
#else
  newXS("X11::GLX::GLX_HEIGHT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_EVENT_MASK
  newCONSTSUB(stash, "GLX_EVENT_MASK", newSViv(GLX_EVENT_MASK));
#else
  newXS("X11::GLX::GLX_EVENT_MASK", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_DAMAGED
  newCONSTSUB(stash, "GLX_DAMAGED", newSViv(GLX_DAMAGED));
#else
  newXS("X11::GLX::GLX_DAMAGED", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SAVED
  newCONSTSUB(stash, "GLX_SAVED", newSViv(GLX_SAVED));
#else
  newXS("X11::GLX::GLX_SAVED", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_WINDOW
  newCONSTSUB(stash, "GLX_WINDOW", newSViv(GLX_WINDOW));
#else
  newXS("X11::GLX::GLX_WINDOW", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PBUFFER
  newCONSTSUB(stash, "GLX_PBUFFER", newSViv(GLX_PBUFFER));
#else
  newXS("X11::GLX::GLX_PBUFFER", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PBUFFER_HEIGHT
  newCONSTSUB(stash, "GLX_PBUFFER_HEIGHT", newSViv(GLX_PBUFFER_HEIGHT));
#else
  newXS("X11::GLX::GLX_PBUFFER_HEIGHT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PBUFFER_WIDTH
  newCONSTSUB(stash, "GLX_PBUFFER_WIDTH", newSViv(GLX_PBUFFER_WIDTH));
#else
  newXS("X11::GLX::GLX_PBUFFER_WIDTH", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RGBA_BIT
  newCONSTSUB(stash, "GLX_RGBA_BIT", newSViv(GLX_RGBA_BIT));
#else
  newXS("X11::GLX::GLX_RGBA_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_COLOR_INDEX_BIT
  newCONSTSUB(stash, "GLX_COLOR_INDEX_BIT", newSViv(GLX_COLOR_INDEX_BIT));
#else
  newXS("X11::GLX::GLX_COLOR_INDEX_BIT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_PBUFFER_CLOBBER_MASK
  newCONSTSUB(stash, "GLX_PBUFFER_CLOBBER_MASK", newSViv(GLX_PBUFFER_CLOBBER_MASK));
#else
  newXS("X11::GLX::GLX_PBUFFER_CLOBBER_MASK", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SAMPLE_BUFFERS
  newCONSTSUB(stash, "GLX_SAMPLE_BUFFERS", newSViv(GLX_SAMPLE_BUFFERS));
#else
  newXS("X11::GLX::GLX_SAMPLE_BUFFERS", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_SAMPLES
  newCONSTSUB(stash, "GLX_SAMPLES", newSViv(GLX_SAMPLES));
#else
  newXS("X11::GLX::GLX_SAMPLES", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BIND_TO_TEXTURE_RGB_EXT
  newCONSTSUB(stash, "GLX_BIND_TO_TEXTURE_RGB_EXT", newSViv(GLX_BIND_TO_TEXTURE_RGB_EXT));
#else
  newXS("X11::GLX::GLX_BIND_TO_TEXTURE_RGB_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BIND_TO_TEXTURE_RGBA_EXT
  newCONSTSUB(stash, "GLX_BIND_TO_TEXTURE_RGBA_EXT", newSViv(GLX_BIND_TO_TEXTURE_RGBA_EXT));
#else
  newXS("X11::GLX::GLX_BIND_TO_TEXTURE_RGBA_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BIND_TO_MIPMAP_TEXTURE_EXT
  newCONSTSUB(stash, "GLX_BIND_TO_MIPMAP_TEXTURE_EXT", newSViv(GLX_BIND_TO_MIPMAP_TEXTURE_EXT));
#else
  newXS("X11::GLX::GLX_BIND_TO_MIPMAP_TEXTURE_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BIND_TO_TEXTURE_TARGETS_EXT
  newCONSTSUB(stash, "GLX_BIND_TO_TEXTURE_TARGETS_EXT", newSViv(GLX_BIND_TO_TEXTURE_TARGETS_EXT));
#else
  newXS("X11::GLX::GLX_BIND_TO_TEXTURE_TARGETS_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_Y_INVERTED_EXT
  newCONSTSUB(stash, "GLX_Y_INVERTED_EXT", newSViv(GLX_Y_INVERTED_EXT));
#else
  newXS("X11::GLX::GLX_Y_INVERTED_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_FORMAT_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_FORMAT_EXT", newSViv(GLX_TEXTURE_FORMAT_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_FORMAT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_TARGET_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_TARGET_EXT", newSViv(GLX_TEXTURE_TARGET_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_TARGET_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_MIPMAP_TEXTURE_EXT
  newCONSTSUB(stash, "GLX_MIPMAP_TEXTURE_EXT", newSViv(GLX_MIPMAP_TEXTURE_EXT));
#else
  newXS("X11::GLX::GLX_MIPMAP_TEXTURE_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_FORMAT_NONE_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_FORMAT_NONE_EXT", newSViv(GLX_TEXTURE_FORMAT_NONE_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_FORMAT_NONE_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_FORMAT_RGB_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_FORMAT_RGB_EXT", newSViv(GLX_TEXTURE_FORMAT_RGB_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_FORMAT_RGB_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_FORMAT_RGBA_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_FORMAT_RGBA_EXT", newSViv(GLX_TEXTURE_FORMAT_RGBA_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_FORMAT_RGBA_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_1D_BIT_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_1D_BIT_EXT", newSViv(GLX_TEXTURE_1D_BIT_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_1D_BIT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_2D_BIT_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_2D_BIT_EXT", newSViv(GLX_TEXTURE_2D_BIT_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_2D_BIT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_RECTANGLE_BIT_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_RECTANGLE_BIT_EXT", newSViv(GLX_TEXTURE_RECTANGLE_BIT_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_RECTANGLE_BIT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_1D_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_1D_EXT", newSViv(GLX_TEXTURE_1D_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_1D_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_2D_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_2D_EXT", newSViv(GLX_TEXTURE_2D_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_2D_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_TEXTURE_RECTANGLE_EXT
  newCONSTSUB(stash, "GLX_TEXTURE_RECTANGLE_EXT", newSViv(GLX_TEXTURE_RECTANGLE_EXT));
#else
  newXS("X11::GLX::GLX_TEXTURE_RECTANGLE_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FRONT_LEFT_EXT
  newCONSTSUB(stash, "GLX_FRONT_LEFT_EXT", newSViv(GLX_FRONT_LEFT_EXT));
#else
  newXS("X11::GLX::GLX_FRONT_LEFT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FRONT_RIGHT_EXT
  newCONSTSUB(stash, "GLX_FRONT_RIGHT_EXT", newSViv(GLX_FRONT_RIGHT_EXT));
#else
  newXS("X11::GLX::GLX_FRONT_RIGHT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BACK_LEFT_EXT
  newCONSTSUB(stash, "GLX_BACK_LEFT_EXT", newSViv(GLX_BACK_LEFT_EXT));
#else
  newXS("X11::GLX::GLX_BACK_LEFT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BACK_RIGHT_EXT
  newCONSTSUB(stash, "GLX_BACK_RIGHT_EXT", newSViv(GLX_BACK_RIGHT_EXT));
#else
  newXS("X11::GLX::GLX_BACK_RIGHT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FRONT_EXT
  newCONSTSUB(stash, "GLX_FRONT_EXT", newSViv(GLX_FRONT_EXT));
#else
  newXS("X11::GLX::GLX_FRONT_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_BACK_EXT
  newCONSTSUB(stash, "GLX_BACK_EXT", newSViv(GLX_BACK_EXT));
#else
  newXS("X11::GLX::GLX_BACK_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX0_EXT
  newCONSTSUB(stash, "GLX_AUX0_EXT", newSViv(GLX_AUX0_EXT));
#else
  newXS("X11::GLX::GLX_AUX0_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX1_EXT
  newCONSTSUB(stash, "GLX_AUX1_EXT", newSViv(GLX_AUX1_EXT));
#else
  newXS("X11::GLX::GLX_AUX1_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX2_EXT
  newCONSTSUB(stash, "GLX_AUX2_EXT", newSViv(GLX_AUX2_EXT));
#else
  newXS("X11::GLX::GLX_AUX2_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX3_EXT
  newCONSTSUB(stash, "GLX_AUX3_EXT", newSViv(GLX_AUX3_EXT));
#else
  newXS("X11::GLX::GLX_AUX3_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX4_EXT
  newCONSTSUB(stash, "GLX_AUX4_EXT", newSViv(GLX_AUX4_EXT));
#else
  newXS("X11::GLX::GLX_AUX4_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX5_EXT
  newCONSTSUB(stash, "GLX_AUX5_EXT", newSViv(GLX_AUX5_EXT));
#else
  newXS("X11::GLX::GLX_AUX5_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX6_EXT
  newCONSTSUB(stash, "GLX_AUX6_EXT", newSViv(GLX_AUX6_EXT));
#else
  newXS("X11::GLX::GLX_AUX6_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX7_EXT
  newCONSTSUB(stash, "GLX_AUX7_EXT", newSViv(GLX_AUX7_EXT));
#else
  newXS("X11::GLX::GLX_AUX7_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX8_EXT
  newCONSTSUB(stash, "GLX_AUX8_EXT", newSViv(GLX_AUX8_EXT));
#else
  newXS("X11::GLX::GLX_AUX8_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_AUX9_EXT
  newCONSTSUB(stash, "GLX_AUX9_EXT", newSViv(GLX_AUX9_EXT));
#else
  newXS("X11::GLX::GLX_AUX9_EXT", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_VENDOR_ID_MESA
  newCONSTSUB(stash, "GLX_RENDERER_VENDOR_ID_MESA", newSViv(GLX_RENDERER_VENDOR_ID_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_VENDOR_ID_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_DEVICE_ID_MESA
  newCONSTSUB(stash, "GLX_RENDERER_DEVICE_ID_MESA", newSViv(GLX_RENDERER_DEVICE_ID_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_DEVICE_ID_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_VERSION_MESA
  newCONSTSUB(stash, "GLX_RENDERER_VERSION_MESA", newSViv(GLX_RENDERER_VERSION_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_VERSION_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_ACCELERATED_MESA
  newCONSTSUB(stash, "GLX_RENDERER_ACCELERATED_MESA", newSViv(GLX_RENDERER_ACCELERATED_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_ACCELERATED_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_VIDEO_MEMORY_MESA
  newCONSTSUB(stash, "GLX_RENDERER_VIDEO_MEMORY_MESA", newSViv(GLX_RENDERER_VIDEO_MEMORY_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_VIDEO_MEMORY_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_UNIFIED_MEMORY_ARCHITECTURE_MESA
  newCONSTSUB(stash, "GLX_RENDERER_UNIFIED_MEMORY_ARCHITECTURE_MESA", newSViv(GLX_RENDERER_UNIFIED_MEMORY_ARCHITECTURE_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_UNIFIED_MEMORY_ARCHITECTURE_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_PREFERRED_PROFILE_MESA
  newCONSTSUB(stash, "GLX_RENDERER_PREFERRED_PROFILE_MESA", newSViv(GLX_RENDERER_PREFERRED_PROFILE_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_PREFERRED_PROFILE_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_OPENGL_CORE_PROFILE_VERSION_MESA
  newCONSTSUB(stash, "GLX_RENDERER_OPENGL_CORE_PROFILE_VERSION_MESA", newSViv(GLX_RENDERER_OPENGL_CORE_PROFILE_VERSION_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_OPENGL_CORE_PROFILE_VERSION_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_OPENGL_COMPATIBILITY_PROFILE_VERSION_MESA
  newCONSTSUB(stash, "GLX_RENDERER_OPENGL_COMPATIBILITY_PROFILE_VERSION_MESA", newSViv(GLX_RENDERER_OPENGL_COMPATIBILITY_PROFILE_VERSION_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_OPENGL_COMPATIBILITY_PROFILE_VERSION_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_OPENGL_ES_PROFILE_VERSION_MESA
  newCONSTSUB(stash, "GLX_RENDERER_OPENGL_ES_PROFILE_VERSION_MESA", newSViv(GLX_RENDERER_OPENGL_ES_PROFILE_VERSION_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_OPENGL_ES_PROFILE_VERSION_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_OPENGL_ES2_PROFILE_VERSION_MESA
  newCONSTSUB(stash, "GLX_RENDERER_OPENGL_ES2_PROFILE_VERSION_MESA", newSViv(GLX_RENDERER_OPENGL_ES2_PROFILE_VERSION_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_OPENGL_ES2_PROFILE_VERSION_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_RENDERER_ID_MESA
  newCONSTSUB(stash, "GLX_RENDERER_ID_MESA", newSViv(GLX_RENDERER_ID_MESA));
#else
  newXS("X11::GLX::GLX_RENDERER_ID_MESA", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GLX_FLOAT_COMPONENTS_NV
  newCONSTSUB(stash, "GLX_FLOAT_COMPONENTS_NV", newSViv(GLX_FLOAT_COMPONENTS_NV));
#else
  newXS("X11::GLX::GLX_FLOAT_COMPONENTS_NV", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_INVALID_ENUM
  newCONSTSUB(stash, "GL_INVALID_ENUM", newSViv(GL_INVALID_ENUM));
#else
  newXS("X11::GLX::GL_INVALID_ENUM", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_INVALID_VALUE
  newCONSTSUB(stash, "GL_INVALID_VALUE", newSViv(GL_INVALID_VALUE));
#else
  newXS("X11::GLX::GL_INVALID_VALUE", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_INVALID_OPERATION
  newCONSTSUB(stash, "GL_INVALID_OPERATION", newSViv(GL_INVALID_OPERATION));
#else
  newXS("X11::GLX::GL_INVALID_OPERATION", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_INVALID_FRAMEBUFFER_OPERATION
  newCONSTSUB(stash, "GL_INVALID_FRAMEBUFFER_OPERATION", newSViv(GL_INVALID_FRAMEBUFFER_OPERATION));
#else
  newXS("X11::GLX::GL_INVALID_FRAMEBUFFER_OPERATION", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_OUT_OF_MEMORY
  newCONSTSUB(stash, "GL_OUT_OF_MEMORY", newSViv(GL_OUT_OF_MEMORY));
#else
  newXS("X11::GLX::GL_OUT_OF_MEMORY", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_STACK_OVERFLOW
  newCONSTSUB(stash, "GL_STACK_OVERFLOW", newSViv(GL_STACK_OVERFLOW));
#else
  newXS("X11::GLX::GL_STACK_OVERFLOW", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_STACK_UNDERFLOW
  newCONSTSUB(stash, "GL_STACK_UNDERFLOW", newSViv(GL_STACK_UNDERFLOW));
#else
  newXS("X11::GLX::GL_STACK_UNDERFLOW", XS_X11__GLX__const_unavailable, file);
#endif
#ifdef GL_TABLE_TOO_LARGE
  newCONSTSUB(stash, "GL_TABLE_TOO_LARGE", newSViv(GL_TABLE_TOO_LARGE));
#else
  newXS("X11::GLX::GL_TABLE_TOO_LARGE", XS_X11__GLX__const_unavailable, file);
#endif
# END GENERATED BOOT CONSTANTS
# ----------------------------------------------------------------------------
