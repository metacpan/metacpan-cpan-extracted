#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <webgpu/webgpu.h>

#include "xs/mg.c"

/* ------------------------------------------------------------------
   WebGPU::Direct::MappedBuffer
   ------------------------------------------------------------------ */

typedef SV* WebGPU__Direct__MappedBuffer;

typedef struct mapped_buffer {
  Size_t size;
  const char *buffer;
} mapped_buffer;

void WebGPU__Direct__MappedBuffer__unpack(pTHX_ SV *THIS )
{
  if (!SvROK(THIS) || !sv_derived_from(THIS, "WebGPU::Direct::MappedBuffer"))
  {
    croak_nocontext("%s: %s is not of type %s",
      "WebGPU::Direct::MappedBuffer",
      "THIS", "WebGPU::Direct::MappedBuffer");
  }

  HV *h = (HV *)SvRV(THIS);
  mapped_buffer *n = (mapped_buffer *) _get_struct_ptr(aTHX_ THIS, newSVpvs("WebGPU::Direct::MappedBuffer"));
  if ( !n )
  {
    croak("%s: Cannot find Memory Bufffer", "WebGPU::Direct::MappedBuffer");
  }

  SV **f;

  /* Find the field from the hash */
  f = hv_fetchs(h, "buffer", 1);

  /* If the field cannot be used, croak*/
  if ( !( f && *f ) )
  {
    croak("%s: Cannot save buffer to object", "WebGPU::Direct::MappedBuffer");
  }

    if ( SvREADONLY(*f) )
    {
      SV *new = newSV(0);
      f = hv_stores(h, "buffer", new);

      if ( !( f && *f ) )
      {
        croak("%s: Could not save new value for buffer", "WebGPU::Direct::MappedBuffer");
      }
      SvREFCNT_inc(*f);
    }

  sv_setpvn(*f, n->buffer, n->size);

  {
    SV *size = newSViv(n->size);
    SvREFCNT_inc(size);
    f = hv_stores(h, "size", size);

    if ( !f )
    {
      SvREFCNT_dec(size);
      croak("Could not save value to hash for size in type %s", "WebGPU::Direct::MappedBuffer");
    }
  }

  return;
}

void WebGPU__Direct__MappedBuffer__pack(pTHX_ SV *THIS )
{
  if (!SvROK(THIS) || !sv_derived_from(THIS, "WebGPU::Direct::MappedBuffer"))
  {
    croak_nocontext("%s: %s is not of type %s",
      "WebGPU::Direct::MappedBuffer",
      "THIS", "WebGPU::Direct::MappedBuffer");
  }

  HV *h = (HV *)SvRV(THIS);
  mapped_buffer *n = (mapped_buffer *) _get_struct_ptr(aTHX_ THIS, newSVpvs("WebGPU::Direct::MappedBuffer"));
  if ( !n )
  {
    croak("%s: Cannot find Memory Bufffer", "WebGPU::Direct::MappedBuffer");
  }

  SV **f;

  /* Find the field from the hash */
  f = hv_fetchs(h, "buffer", 0);

  /* Save the new value to the field */
  if ( f && *f )
  {
    STRLEN len = n->size;
    STRLEN vlen;
    const char *v = SvPVbyte(*f, vlen);

    if ( vlen < len )
    {
      Zero(n->buffer+vlen, len-vlen, char);
      len = vlen;
    }
    Copy(v, n->buffer, len, char);
  }

  return WebGPU__Direct__MappedBuffer__unpack(aTHX_ THIS);
}

SV *WebGPU__Direct__MappedBuffer_buffer(pTHX_ SV *THIS, SV *value)
{
  HV *h = (HV *)SvRV(THIS);
  SV **f;

  if ( value && SvOK(value) )
  {
    SvREFCNT_inc(value);
    f = hv_stores(h, "buffer", value);

    if ( !f )
    {
      SvREFCNT_dec(value);
      croak("%s: Could not save value to hash for %s", "WebGPU::Direct::MappedBuffer", "buffer");
    }

    WebGPU__Direct__MappedBuffer__pack(aTHX_ THIS);
  }

  f = hv_fetchs(h, "buffer", 0);
  SvREFCNT_inc(*f);

  return *f;
}

SV *WebGPU__Direct__MappedBuffer__wrap(pTHX_ const char * buffer, Size_t size)
{
  HV *h = newHV();
  SV *RETVAL = sv_2mortal(newRV((SV*)h));

  mapped_buffer *n;
  Newxz(n, 1, mapped_buffer);

  n->buffer = buffer;
  n->size = size;

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv("WebGPU::Direct::MappedBuffer", GV_ADD));
  WebGPU__Direct__MappedBuffer__unpack(aTHX_ RETVAL);
  return SvREFCNT_inc(RETVAL);
}

/* ------------------------------------------------------------------
   END
   ------------------------------------------------------------------ */

#include "xs/webgpu_wrap.c"
#include "xs/x11.c"
#include "xs/wayland.c"
#include "xs/win32.c"

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::XS            PREFIX = wgpu

INCLUDE: xs/webgpu.xs

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::StringView    PREFIX = wgpu

SV *
as_string(THIS)
        SV *THIS
    PROTOTYPE: $;
    CODE:
        WGPUStringView str = *(WGPUStringView *) _get_struct_ptr(aTHX_ THIS, newSVpvs("WebGPU::Direct::StringView"));
        RETVAL = string_view_to_sv( str );
    OUTPUT:
        RETVAL

BOOT:
{
  HV *stash = gv_stashpv("WebGPU::Direct::StringView", 0);

  newCONSTSUB(stash, "STRLEN", newSViv(WGPU_STRLEN));
}

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::Enum      PREFIX = wgpu

# /* Mark an SV as an Enum to make the check faster. We cleverly do this by
#    making THIS a trivar: intentionally ensuring that IV, NV and PV are all set */

SV *
_mark_enum(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        SvNV(THIS);
    OUTPUT:
        THIS

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::MappedBuffer      PREFIX = wgpu

void
pack(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        WebGPU__Direct__MappedBuffer__pack( aTHX_ THIS );

void
unpack(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        WebGPU__Direct__MappedBuffer__unpack( aTHX_ THIS );

SV *
buffer(THIS, value = NULL)
        SV *THIS
        SV *value
    PROTOTYPE: $;$
    CODE:
        RETVAL = WebGPU__Direct__MappedBuffer_buffer( aTHX_ THIS, value );
    OUTPUT:
        RETVAL

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::Opaque        PREFIX = wgpu

SV *
__wrap(val)
        IV    val
    PROTOTYPE: $
    CODE:
        RETVAL = _void__wrap((void *)val);
    OUTPUT:
        RETVAL

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct                PREFIX = wgpu

WebGPU::Direct::SurfaceSourceXlibWindow
new_window_x11(CLASS, xw = 640, yh = 360)
        SV *  CLASS
        int   xw
        int   yh
    PROTOTYPE: $
    CODE:
#ifdef HAS_X11
#define _DEF_X11 1
        SV *THIS = _new( newSVpvs("WebGPU::Direct::SurfaceSourceXlibWindow"), NULL );
        WGPUSurfaceSourceXlibWindow *result = (WGPUSurfaceSourceXlibWindow *) _get_struct_ptr(aTHX_ THIS, NULL);
        if ( ! x11_window(result, xw, yh) )
        {
          Perl_croak(aTHX_ "Could not create an X11 window");
        }

        _unpack(THIS);

        RETVAL = THIS;
#else
#define _DEF_X11 0
        Perl_croak(aTHX_ "Cannot create X11 window: X11 not found");
#endif
    OUTPUT:
        RETVAL

WebGPU::Direct::SurfaceSourceWaylandSurface
new_window_wayland(CLASS, xw = 640, yh = 360)
        SV *  CLASS
        int   xw
        int   yh
    PROTOTYPE: $
    CODE:
#ifdef HAS_WAYLAND
#define _DEF_WAYLAND 1
        SV *THIS = _new( newSVpvs("WebGPU::Direct::SurfaceSourceWaylandSurface"), NULL );
        WGPUSurfaceSourceWaylandSurface *result = (WGPUSurfaceSourceWaylandSurface *) _get_struct_ptr(aTHX_ THIS, NULL);
        if ( ! wayland_window(result, xw, yh) )
        {
          Perl_croak(aTHX_ "Could not create an Wayland window");
        }

        _unpack(THIS);

        RETVAL = THIS;
#else
#define _DEF_WAYLAND 0
        Perl_croak(aTHX_ "Cannot create Wayland window: Wayland not found");
#endif
    OUTPUT:
        RETVAL

WebGPU::Direct::SurfaceSourceWindowsHWND
new_window_win32(CLASS, xw = 640, yh = 360)
        SV *  CLASS
        int   xw
        int   yh
    PROTOTYPE: $
    CODE:
#ifdef HAS_WIN32
#define _DEF_WIN32 1
        SV *THIS = _new( newSVpvs("WebGPU::Direct::SurfaceSourceWindowsHWND"), NULL );
        CV *pec = NULL;
        WGPUSurfaceSourceWindowsHWND *result = (WGPUSurfaceSourceWindowsHWND *) _get_struct_ptr(aTHX_ THIS, NULL);
        if ( ! win32_window(result, &pec, xw, yh) )
        {
          Perl_croak(aTHX_ "Could not create an win32 window");
        }

        _unpack(THIS);

        if ( pec )
        {
          SV *cv_ref = SvREFCNT_inc(newRV((SV *)pec));
          SV **f = hv_stores((HV *)SvRV(THIS), "processEvents", cv_ref);
          if ( !f )
          {
            SvREFCNT_dec(cv_ref);
            croak("Could not save processEvents value to object");
          }
        }
        RETVAL = THIS;
#else
#define _DEF_WIN32 0
        Perl_croak(aTHX_ "Cannot create win32 window: win32 not found");
#endif
    OUTPUT:
        RETVAL

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::XS            PREFIX = wgpu

SV *
_x11_xlib_display_to_opaque(display)
        SV *  display
    PROTOTYPE: $
    CODE:
        const char *base = "X11::Xlib::Display";
        if (!sv_derived_from(display, base) )
        {
          croak("Cannot coerce X11 display from %s; not of type %s", SvPVbyte_nolen(display), base);
        }

        RETVAL = &PL_sv_undef;

        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(display);
        PUTBACK;

        int count = call_method("_pointer_value", G_SCALAR);

        SPAGAIN;

        if (count != 1)
        {
          croak("Could not call _pointer_value on %s\n", SvPV_nolen(display));
        }

        SV *pointer_value = SvREFCNT_inc(POPs);

        if ( !SvOK(pointer_value))
        {
          croak("Could not get _pointer_value for %s\n", SvPV_nolen(display));
        }

        if (SvPOK(pointer_value) && SvCUR(pointer_value) == sizeof(void*))
        {
          void *opaque = *(void **) SvPVX(pointer_value);
          RETVAL = _void__wrap(opaque);
        }

        SvREFCNT_dec(pointer_value);
        PUTBACK;
        FREETMPS;
        LEAVE;
    OUTPUT:
        RETVAL

SV *
_x11_xcb_conn_to_opaque(conn)
        SV *  conn
    PROTOTYPE: $
    CODE:
        const char *base = "X11::XCB::Connection";
        if (!sv_derived_from(conn, base) )
        {
          croak("Cannot coerce XCB connection from %s; not of type %s", SvPVbyte_nolen(conn), base);
        }

        RETVAL = &PL_sv_undef;

        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(conn);
        PUTBACK;

        int count = call_method("get_xcb_conn", G_SCALAR);

        SPAGAIN;

        if (count != 1)
        {
          croak("Could not call get_xcb_conn on %s\n", SvPV_nolen(conn));
        }

        IV conn_value = POPi;

        if (conn_value)
        {
          RETVAL = _void__wrap((void *)conn_value);
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    OUTPUT:
        RETVAL


BOOT:
{
  HV *stash = gv_stashpv("WebGPU::Direct::XS", 0);

  newCONSTSUB(stash, "HAS_X11", newSViv(_DEF_X11));
  newCONSTSUB(stash, "HAS_WAYLAND", newSViv(_DEF_WAYLAND));
  newCONSTSUB(stash, "HAS_WIN32", newSViv(_DEF_WIN32));
}

