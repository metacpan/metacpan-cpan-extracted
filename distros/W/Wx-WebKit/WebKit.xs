#define STRICT
#include <wx/defs.h>
#include <wx/html/webkit.h>

#include "cpp/wxapi.h" // AFTER wxheaders

#undef THIS

MODULE=Wx__WebKit PACKAGE=Wx::WebKit

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

MODULE = Wx__WebKit            PACKAGE = Wx::WebKitCtrl

wxWebKitCtrl *
wxWebKitCtrl::new(parent, id, strURL, pos = wxDefaultPosition, size = wxDefaultSize, style = 0)
  wxWindow* parent
  wxWindowID id
  wxString strURL
  wxPoint pos
  wxSize size
  long style
  CODE:
    RETVAL = new wxWebKitCtrl( parent, id, strURL, pos, size, style);
    wxPli_create_evthandler( aTHX_ RETVAL, CLASS );
  OUTPUT: RETVAL

bool
wxWebKitCtrl::Create(parent, winID, strURL, pos = wxDefaultPosition, size = wxDefaultSize, style = 0)
  wxWindow *parent
  wxWindowID winID
  wxString strURL
  wxPoint pos
  wxSize size
  long style

void
wxWebKitCtrl::LoadURL(url)
  wxString url

bool
wxWebKitCtrl::CanGoBack()

bool
wxWebKitCtrl::CanGoForward()

bool
wxWebKitCtrl::GoBack()

bool
wxWebKitCtrl::GoForward()

void
wxWebKitCtrl::Reload()

void
wxWebKitCtrl::Stop()

bool
wxWebKitCtrl::CanGetPageSource()

wxString
wxWebKitCtrl::GetPageSource()

void
wxWebKitCtrl::SetPageSource(source, baseURL = wxEmptyString)
  wxString source
  wxString baseURL

#void
#wxWebKitCtrl::OnSize(event)
#  wxSizeEvent * event

