/////////////////////////////////////////////////////////////////////////////
// Name:        GLCanvas.xs
// Purpose:     XSor Wx::GLCanvas.pm
// Author:      Mattia Barbon
// Modified by:
// Created:     26/07/2003
// RCS-ID:      $Id: GLCanvas.xs 2489 2008-10-27 19:50:51Z mbarbon $
// Copyright:   (c) 2003, 2005, 2007-2008 Mattia Barbon
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#define STRICT
#define PERL_NO_GET_CONTEXT
#define WXINTL_NO_GETTEXT_MACRO 1

#include <wx/defs.h>
#include "wx/window.h"
#include "cpp/wxapi.h"
#include "cpp/overload.h"
#include "cpp/ovl_const.h"
#include "cpp/ovl_const.cpp"

#undef THIS

#if WXPERL_W_VERSION_GE( 2, 5, 0 ) && wxUSE_GLCANVAS
    #include <wx/glcanvas.h>
#else
    #ifdef __WXMSW__
        #undef  wxUSE_GLCANVAS
        #define wxUSE_GLCANVAS 1
        #define WXDLLIMPEXP_GL

        #include "wx/myglcanvas.h"
        #include "wx/glcanvas.cpp"
    #else
        #include <wx/glcanvas.h>
    #endif
#endif

int* wxPli_get_attribute_list( pTHX_ SV* avref )
{
    if( !avref )
        return NULL;

    // special case for empty array
    if(    SvROK( avref )
        && SvTYPE( SvRV( avref ) ) == SVt_PVAV
        && av_len( (AV*) SvRV( avref ) ) == -1 )
        return NULL;

    int* array;
    wxPli_av_2_intarray( aTHX_ avref, &array );

    return array;
}

static double constant( const char *name, int arg )
{
    errno = 0;

#define r( n ) \
    if( strEQ( name, #n ) ) \
        return n;

    switch( name[0] )
    {
    case 'W':
        r( WX_GL_RGBA );
        r( WX_GL_BUFFER_SIZE );
        r( WX_GL_LEVEL );
        r( WX_GL_DOUBLEBUFFER );
        r( WX_GL_STEREO );
        r( WX_GL_AUX_BUFFERS );
        r( WX_GL_MIN_RED );
        r( WX_GL_MIN_GREEN );
        r( WX_GL_MIN_BLUE );
        r( WX_GL_MIN_ALPHA );
        r( WX_GL_DEPTH_SIZE );
        r( WX_GL_STENCIL_SIZE );
        r( WX_GL_MIN_ACCUM_RED );
        r( WX_GL_MIN_ACCUM_GREEN );
        r( WX_GL_MIN_ACCUM_BLUE );
        r( WX_GL_MIN_ACCUM_ALPHA );
        break;
    default:
        break;
    }

#undef r
    errno = EINVAL;

    return 0;
}

MODULE=Wx__GLCanvas PACKAGE=Wx::GLCanvas

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

double
constant( name, arg )
    const char* name
    int arg

## DECLARE_OVERLOAD( wglx, Wx::GLContext )
## DECLARE_OVERLOAD( wglc, Wx::GLCanvas )

void
wxGLCanvas::new( ... )
  PPCODE:
    BEGIN_OVERLOAD()
        MATCH_REDISP_COUNT_ALLOWMORE( wxPliOvl_wwin_n_wpoi_wsiz_n_s, newDefault, 1 )
#if WXPERL_W_VERSION_LT( 2, 9, 0 )
        MATCH_REDISP_COUNT_ALLOWMORE( wxPliOvl_wwin_wglx_n_wpoi_wsiz_n_s, newContext, 2 )
        MATCH_REDISP_COUNT_ALLOWMORE( wxPliOvl_wwin_wglc_n_wpoi_wsiz_n_s, newCanvas, 2 )
#endif
    END_OVERLOAD( Wx::GLCanvas::new )

static wxGLCanvas*
wxGLCanvas::newDefault( parent, id = -1, pos = wxDefaultPosition, size = wxDefaultSize, style = 0, name = wxGLCanvasName, attributes = NULL )
    wxWindow* parent
    wxWindowID id
    wxPoint pos
    wxSize size
    long style
    wxString name
    SV_null* attributes
  CODE:
    wxPliArrayGuard<int> attrs = wxPli_get_attribute_list( aTHX_ attributes );
#if WXPERL_W_VERSION_GE( 2, 9, 0 )
    RETVAL = new wxGLCanvas( parent, id, attrs, pos, size, style, name );
#else
    RETVAL = new wxGLCanvas( parent, id, pos, size, style, name, attrs );
#endif
    wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
  OUTPUT: RETVAL

#if WXPERL_W_VERSION_GE( 2, 9, 0 )

void
wxGLCanvas::SetCurrent( context )
    wxGLContext* context
  C_ARGS: *context

#else

static wxGLCanvas*
wxGLCanvas::newContext( parent, context, id = -1, pos = wxDefaultPosition, size = wxDefaultSize, style = 0, name = wxGLCanvasName, attributes = NULL )
    wxWindow* parent
    wxGLContext* context
    wxWindowID id
    wxPoint pos
    wxSize size
    long style
    wxString name
    SV_null* attributes
  CODE:
    wxPliArrayGuard<int> attrs = wxPli_get_attribute_list( aTHX_ attributes );
    RETVAL = new wxGLCanvas( parent, context, id, pos, size, style, name, attrs );
    wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
  OUTPUT: RETVAL

static wxGLCanvas*
wxGLCanvas::newCanvas( parent, canvas, id = -1, pos = wxDefaultPosition, size = wxDefaultSize, style = 0, name = wxGLCanvasName, attributes = NULL )
    wxWindow* parent
    wxGLCanvas* canvas
    wxWindowID id
    wxPoint pos
    wxSize size
    long style
    wxString name
    SV_null* attributes
  CODE:
    wxPliArrayGuard<int> attrs = wxPli_get_attribute_list( aTHX_ attributes );
    RETVAL = new wxGLCanvas( parent, canvas, id, pos, size, style, name, attrs );
    wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
  OUTPUT: RETVAL

wxGLContext*
wxGLCanvas::GetContext()

void
wxGLCanvas::SetCurrent()

#endif

#ifdef __WXMSW__

void
wxGLCanvas::SetupPalette( palette )
    wxPalette* palette
  CODE:
    THIS->SetupPalette( *palette );

#endif

void
wxGLCanvas::SwapBuffers()

MODULE=Wx__GLCanvas PACKAGE=Wx::GLContext

#if    ( WXPERL_W_VERSION_GE( 2, 7, 1 ) && !defined( __WXMAC__ ) ) \
    || WXPERL_W_VERSION_GE( 2, 9, 0 )

wxGLContext*
wxGLContext::new(win, cxt = NULL )
    wxGLCanvas* win
    wxGLContext* cxt
  CODE:
    RETVAL = cxt ? new wxGLContext( win, cxt )
                 : new wxGLContext( win );
  OUTPUT: RETVAL

#else
#if !defined( __WXMAC__ )

wxGLContext*
wxGLContext::new( isRGB, win, palette = (wxPalette*)&wxNullPalette, cxt = NULL )
    bool isRGB
    wxGLCanvas* win
    wxPalette* palette
    wxGLContext* cxt
  CODE:
    RETVAL = cxt ? new wxGLContext( isRGB, win, *palette, cxt )
                 : new wxGLContext( isRGB, win, *palette );
  OUTPUT: RETVAL

#endif
#endif

#if    ( WXPERL_W_VERSION_GE( 2, 7, 1 ) && !defined( __WXMAC__ ) ) \
    || WXPERL_W_VERSION_GE( 2, 9, 0 )

void
wxGLContext::SetCurrent( wxGLCanvas* canvas )
  C_ARGS: *canvas

#else

void
wxGLContext::SetCurrent()

void
wxGLContext::SwapBuffers()

#endif

#if WXPERL_W_VERSION_LE( 2, 7, 0 )

void
wxGLContext::SetColour( colour )
    wxString colour

#endif
