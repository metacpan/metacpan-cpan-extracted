#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <GL/glx.h>
#include <GL/glxext.h>
#include "PerlXlib.h"

// typedef GLXContext ( * PFNGLXIMPORTCONTEXTEXTPROC) (Display* dpy, GLXContextID contextID);
// typedef GLXContextID ( * PFNGLXGETCONTEXTIDEXTPROC) (const GLXContext context);
// typedef void ( * PFNGLXFREECONTEXTEXTPROC) (Display* dpy, GLXContext context);
// typedef Bool ( * PFNGLXQUERYCONTEXTINFOEXTPROC) (Display *dpy, GLXContext context, int id, int *out_val);
// PFNGLXIMPORTCONTEXTEXTPROC    import_context_fn;
// PFNGLXGETCONTEXTIDEXTPROC     get_context_id_fn;
// PFNGLXQUERYCONTEXTINFOEXTPROC query_context_info_fn;
// PFNGLXFREECONTEXTEXTPROC      free_context_fn;

//GLXContextID glXGetContextID(const GLXContext context);

extern GLXContextID glXGetContextIDEXT(GLXContext cx);
extern Bool glXQueryContextInfoEXT(Display *dpy, GLXContext cx, int attr, int *out_val);
extern GLXContext glXImportContextEXT(Display *dpy, GLXContextID id);
extern void glXFreeContextEXT(Display *dpy, GLXContext cx);

typedef GLXContext GLXContextOrNull;
typedef GLXContext GLXContextImported;

MODULE = X11::GLX                  PACKAGE = X11::GLX

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
		SV *tmp, **ep;
		AV *attr_av;
		HV *attr_hv;
		int i, n;
		XVisualInfo *match;
		int default_attrs[] = {
			GLX_USE_GL, GLX_RGBA,
			GLX_RED_SIZE, 8, GLX_GREEN_SIZE, 8, GLX_BLUE_SIZE, 8, GLX_ALPHA_SIZE, 8,
			GLX_DOUBLEBUFFER, None
		};
	PPCODE:
		if (!attrs || !SvOK(attrs)) {
			match= glXChooseVisual(dpy, screen, default_attrs);
		}
		else if (SvROK(attrs) && (SvTYPE(attrs) == SVt_PVAV)) {
			attr_av= (AV*) SvRV(attrs);
			n= av_len(attr_av)+1;
			tmp= sv_2mortal(newSV(0));
			sv_grow(tmp, sizeof(int) * (n+1));
			for (i= 0; i<n; i++) {
				ep= av_fetch(attr_av, i, 0);
				if (!ep)
					croak("Found NULL in attributes array");
				((int*)(void*)SvPVX(tmp))[i]= SvIV(*ep);
			}
			((int*)(void*)SvPVX(tmp))[n]= None;
			match= glXChooseVisual(dpy, screen, ((int*)(void*)SvPVX(tmp)));
		}
		if (!match)
			croak("glXChooseVisual failed");
		PUSHs( sv_2mortal( sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", (void*)match, sizeof(XVisualInfo)) ) );
		XFree(match);

GLXContext
glXCreateContext(dpy, vis_info, shared, direct)
	Display *dpy
	XVisualInfo *vis_info
	GLXContextOrNull shared
	Bool direct

void
glXDestroyContext(dpy, cx_sv)
	Display *dpy
	SV *cx_sv
	CODE:
		if (!sv_derived_from(cx_sv, "X11::GLX::Context"))
			croak("second argument must be a GLX::Context");
		if (!SvIV(SvRV(cx_sv)))
			croak("Attempt to destroy X11::GLX::Context twice");
		glXDestroyContext(dpy, (GLXContext) (void*) SvIV(SvRV(cx_sv)));
		// If it was imported, then also free it
		if (sv_isa(cx_sv, "X11::GLX::Context::Imported"))
			glXFreeContextEXT(dpy, (GLXContext) (void*) SvIV(SvRV(cx_sv)));
		else
			// Now, null the pointer to mark it as being properly freed
			SvIV_set(SvRV(cx_sv), 0);

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
glXFreeContextEXT(dpy, cx_sv)
	Display *dpy
	SV *cx_sv
	CODE:
		if (!sv_isa(cx_sv, "X11::GLX::Context::Imported"))
			croak("argument must be a GLX::Context::Imported");
		if (!SvIV(SvRV(cx_sv)))
			croak("Attempt to destroy GLX::Context twice");
		glXFreeContextEXT(dpy, (GLXContext) (void*) SvIV(SvRV(cx_sv)));
		// Now, null the pointer to mark it as being properly freed
		SvIV_set(SvRV(cx_sv), 0);

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

void
DESTROY(self)
	GLXContext self
	CODE:
		// Display pointer is required to free a GLXContext.  Must be handled by perl code.
		if (self) croak("Memory leak! incorrect destruction of GLX::Context");

MODULE = X11::GLX                     PACKAGE = X11::GLX::Context::Imported

void
DESTROY(self)
	GLXContext self
	CODE:
		// Display pointer is required to free a GLXContext.  Must be handled by perl code.
		if (self) croak("Memory leak! incorrect destruction of GLX::Context::Imported");

MODULE = X11::GLX                     PACKAGE = X11::GLX::DWIM


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
_init_ctx(self, dpy, direct, link_to= 0)
	HV *self
	Display *dpy
	int direct
	GLXContextID link_to
	INIT:
		// Create the GL context, either direct or indirect, and optionally sharing
		//  resource IDs with another context.
		//SV *s;
		//const char *extensions= NULL;
		//int visual_id, vmajor, vminor, cx_id;
		//PFNGLXIMPORTCONTEXTEXTPROC    import_context_fn;
		//PFNGLXGETCONTEXTIDEXTPROC     get_context_id_fn;
		//PFNGLXQUERYCONTEXTINFOEXTPROC query_context_info_fn;
		//PFNGLXFREECONTEXTEXTPROC      free_context_fn;
		//GLXContext remote_context= NULL, cx= NULL;
		//XVisualInfo vis_info, *vis_match;
	PPCODE:
		//if (!glXQueryVersion(dpy, &vmajor, &vminor))
		//	croak("Display does not support GLX");
		//
		//// glXQueryExtensionsString doesn't exist before 1.1
		//if (vmajor >= 1 && vminor >= 1) {
		//	// TODO: find out if this needs freed.  Docs don't say, and all examples I can find
		//	// hold onto the pointer for the life of the program.
		//	extensions= glXQueryExtensionsString(dpy, DefaultScreen(dpy));
		//}
		//
		//// Shared GL contexts are not well documented.  The process is to use an
		//// extension to first find an X11 ID for the GL context on the process that
		//// created it, then send that to the peer, then the peer imports the context,
		//// then creates a new context sharing GL IDs with it, then can free the
		//// imported context.   I don't yet know if the new context needs the same
		//// XVisualInfo as the imported one, so I commented that out for now.
		//if (link_to) {
		//	import_context_fn= (PFNGLXIMPORTCONTEXTEXTPROC) glXGetProcAddress("glXImportContextEXT");
		//	free_context_fn=   (PFNGLXFREECONTEXTEXTPROC)   glXGetProcAddress("glXFreeContextEXT");
		//	query_context_info_fn= (PFNGLXQUERYCONTEXTINFOEXTPROC) glXGetProcAddress("glXQueryContextInfoEXT");
		//	if (!import_context_fn || !free_context_fn || !query_context_info_fn)
		//		croak("Can't connect to shared GL context; extension not supported by this X server.");
		//
		//	remote_context= import_context_fn(dpy, link_to);
		//	if (!remote_context)
		//		croak("Can't import remote GL context %d", link_to);
		//	
		//	// Get the visual ID used by the existing context
		//	if (Success != query_context_info_fn(dpy, remote_context, GLX_VISUAL_ID_EXT, &visual_id)) {
		//		free_context_fn(remote_context);
		//		croak("Can't retrieve visual ID of existing GL context");
		//	}
		//	
		//	vis_info.visual_id= visual_id;
		//	vis_match= XGetVisualInfo(dpy, VisualIDMask, &vis_info, &n);
		//	if (vis_match && n > 0)
		//		memcpy(&vis_info, vis_match, sizeof(*vis_match));
		//	if (vis_match)
		//		XFree(vis_match);
		//	if (n > 0)
		//		cx= glXCreateContext(dpy, &vis_info, remote_context, direct);
		//	free_context_fn(dpy, remote_context);
		//	if (n < 1)
		//		croak("Can't find visual %d used by remote context", visual_id);
		//}
		//else {
		//	int attrs[]= { GLX_USE_GL, GLX_RGBA,
		//		GLX_RED_SIZE, 8, GLX_GREEN_SIZE, 8, GLX_BLUE_SIZE, 8, GLX_ALPHA_SIZE, 8,
		//		GLX_DOUBLEBUFFER, None
		//	};
		//	vis_match= glXChooseVisual(dpy, DefaultScreen(dpy), attrs);
		//	if (!vis_match)
		//		croak("glXChooseVisual failed");
		//	memcpy(&vis_info, vis_match, sizeof(*vis_match));
		//	XFree(vis_match);
		//
		//	cx= glXCreateContext(dpy, &vis_info, NULL, direct);
		//}
		//if (!cx)
		//	croak("glXCreateContext failed");
		//
		//cx_id= (get_context_id_fn= (PFNGLXGETCONTEXTIDEXTPROC) glXGetProcAddress("glXGetContextIDEXT"))
		//	? get_context_id_fn(cx) : 0;
		//
		//if (!hv_store(self, "version_major", 13, (s=newSViv(vmajor)), 0)
		// || !hv_store(self, "version_minor", 13, (s=newSViv(vminor)), 0)
		// || (extensions &&
		//	!hv_store(self, "extensions", 10, (s=newSVpv(extensions)), 0))
		// || !hv_store(self, "visual_info", 11, (s=sv_setref_pvn(newSV(0), "X11::Xlib::XVisualInfo", &vis_info, sizeof(vis_info))), 0)
		// || (cx_id &&
		//	!hv_store(self, "context_id", 10, (s=newSViv(cx_id)), 0))
		// || !hv_store(self, "_ctx", 4, (s=sv_setref_pv(newSV(0), "X11::MinimalOpenGLContext::GLXContext", cx)), 0)
		//) {
		//	// hv_store failed, cleanup:
		//	if (sv_isa(s, "X11::MinimalOpenGLContext::GLXContext"))
		//		SvPV_set(SvRV(s), NULL); // prevent warning about destroyed pointer
		//	sv_2mortal(s);
		//	glXDestroyContext(cx);
		//	croak("hv_store failed");
		//}

BOOT:
# BEGIN GENERATED BOOT CONSTANTS
  HV* stash= gv_stashpvn("X11::GLX", 8, 1);
  newCONSTSUB(stash, "GLX_USE_GL", newSViv(GLX_USE_GL));
  newCONSTSUB(stash, "GLX_RGBA", newSViv(GLX_RGBA));
  newCONSTSUB(stash, "GLX_RED_SIZE", newSViv(GLX_RED_SIZE));
  newCONSTSUB(stash, "GLX_GREEN_SIZE", newSViv(GLX_GREEN_SIZE));
  newCONSTSUB(stash, "GLX_BLUE_SIZE", newSViv(GLX_BLUE_SIZE));
  newCONSTSUB(stash, "GLX_ALPHA_SIZE", newSViv(GLX_ALPHA_SIZE));
  newCONSTSUB(stash, "GLX_DOUBLEBUFFER", newSViv(GLX_DOUBLEBUFFER));
  newCONSTSUB(stash, "GLX_VISUAL_ID_EXT", newSViv(GLX_VISUAL_ID_EXT));
  newCONSTSUB(stash, "GLX_SCREEN_EXT", newSViv(GLX_SCREEN_EXT));
# END GENERATED BOOT CONSTANTS
# ----------------------------------------------------------------------------
