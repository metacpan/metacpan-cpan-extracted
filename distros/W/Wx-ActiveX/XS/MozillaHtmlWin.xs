#############################################################################
## Name:        XS/MozillaHtmlWin.xs                                           
## Purpose:     XS for Wx::MozillaHtmlWin
## Author:      Graciliano M. P.
## Modified by:
## SVN-ID:      $Id: IEHtmlWin.xs 2346 2008-04-02 04:36:01Z mdootson $
## Copyright:   (c) 2002 - 2007 Graciliano M. P. and Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

MODULE=Wx PACKAGE=Wx::MozillaHtmlWin

wxMozillaHtmlWin*
wxMozillaHtmlWin::new( parent, id, pos = wxDefaultPosition, size = wxDefaultSize, style = 0, name = wxPanelNameStr )
    wxWindow* parent
    wxWindowID id
    wxPoint pos
    wxSize size
    long style
    wxString name
  CODE:
    RETVAL = new wxPliMozillaHtmlWin( CLASS, parent, id, pos, size, style, name );
  OUTPUT:
    RETVAL       

void
wxMozillaHtmlWin::LoadUrl( url )
  wxString url

bool
wxMozillaHtmlWin::LoadString( html )
  wxString html
  
bool
wxMozillaHtmlWin::LoadStream( is )
  Wx_InputStream* is
  
void
wxMozillaHtmlWin::SetCharset( charset )
  wxString charset
  
void
wxMozillaHtmlWin::SetEditMode( seton )
  bool seton
  
bool
wxMozillaHtmlWin::GetEditMode()

wxString
wxMozillaHtmlWin::GetStringSelection( asHTML = false )
  bool asHTML

wxString
wxMozillaHtmlWin::GetText( asHTML = false )
  bool asHTML

bool
wxMozillaHtmlWin::GoBack()

bool
wxMozillaHtmlWin::GoForward()

bool
wxMozillaHtmlWin::GoHome()

bool
wxMozillaHtmlWin::GoSearch()

bool
wxMozillaHtmlWin::Refresh( level = 0 )
  int level

bool
wxMozillaHtmlWin::Stop()

void
wxMozillaHtmlWin::Print( WithPrompt = false )
  bool WithPrompt

void
wxMozillaHtmlWin::PrintPreview()

MODULE=Wx__ActiveX
