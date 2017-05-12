////////////////////////////////////////////////////////////////////////////////
// Name:        ActiveX.xs
// Purpose:     XS for Wx::ActiveX
// Author:      Graciliano M. P.
// SVN-ID:      $Id: ActiveX.xs 2756 2010-01-11 04:19:37Z mdootson $
// Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
////////////////////////////////////////////////////////////////////////////////
#define PERL_NO_GET_CONTEXT

#ifdef __WXMSW__
#ifdef __MINGW32__
    #define _WIN32_WINNT Windows2003
    #define WINVER Windows2003
    #define _WIN32_IE IE7
#endif
#endif

#include <cpp/wxapi.h>
#include <cpp/wxactivex.cpp>

#undef THIS

#include <cpp/v_cback.h>

MODULE=Wx__ActiveX

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );


#include <cpp/IEHtmlWin.cpp>
#include <cpp/MozillaHtmlWin.cpp>
#include <cpp/PlActiveX.h>
#include <cpp/ax_constants.cpp

INCLUDE: XS/ActiveX.xs
INCLUDE: XS/IEHtmlWin.xs
INCLUDE: XS/MozillaHtmlWin.xs

MODULE=Wx__ActiveX  

#  //FIXME//tricky
#if defined(__WXMSW__)
#undef XS
#define XS( name ) WXXS( name )
#endif



