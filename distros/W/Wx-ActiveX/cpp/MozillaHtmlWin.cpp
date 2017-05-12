
/* SVN-ID:      $Id: MozillaHtmlWin.cpp 2355 2008-04-07 07:03:52Z mdootson $ */
/*
                wxActiveX Library Licence, Version 3
                ====================================

  Copyright (C) 2003 Lindsay Mathieson [, ...]

  Everyone is permitted to copy and distribute verbatim copies
  of this licence document, but changing it is not allowed.

                       wxActiveX LIBRARY LICENCE
     TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
  
  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public Licence as published by
  the Free Software Foundation; either version 2 of the Licence, or (at
  your option) any later version.
  
  This library is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library
  General Public Licence for more details.

  You should have received a copy of the GNU Library General Public Licence
  along with this software, usually in a file named COPYING.LIB.  If not,
  write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA 02111-1307 USA.

  EXCEPTION NOTICE

  1. As a special exception, the copyright holders of this library give
  permission for additional uses of the text contained in this release of
  the library as licenced under the wxActiveX Library Licence, applying
  either version 3 of the Licence, or (at your option) any later version of
  the Licence as published by the copyright holders of version 3 of the
  Licence document.

  2. The exception is that you may use, copy, link, modify and distribute
  under the user's own terms, binary object code versions of works based
  on the Library.

  3. If you copy code from files distributed under the terms of the GNU
  General Public Licence or the GNU Library General Public Licence into a
  copy of this library, as this licence permits, the exception does not
  apply to the code that you add in this way.  To avoid misleading anyone as
  to the status of such modified files, you must delete this exception
  notice from such code and/or adjust the licensing conditions notice
  accordingly.

  4. If you write modifications of your own for this library, it is your
  choice whether to permit this exception to apply to your modifications. 
  If you do not wish that, you must delete the exception notice from such
  code and/or adjust the licensing conditions notice accordingly.
*/

#include "MozillaHtmlWin.h"
#include <wx/strconv.h>
#include <wx/string.h>
#include <wx/event.h>
#include <wx/listctrl.h>
#include <wx/mstream.h>
#include <oleidl.h>
#include <winerror.h>
#include <exdispid.h>
#include <exdisp.h>
#include <olectl.h>
#include <Mshtml.h>
#include <sstream>
using namespace std;

//////////////////////////////////////////////////////////////////////
BEGIN_EVENT_TABLE(wxMozillaHtmlWin, wxActiveX)
END_EVENT_TABLE()


static const CLSID CLSID_MozillaBrowser =
{ 0x1339B54C, 0x3453, 0x11D2,
  { 0x93, 0xB9, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00 } };


//#define PROGID "Shell.Explorer"
//#define PROGID CLSID_WebBrowser
#define MPROGID CLSID_MozillaBrowser
//#define PROGID CLSID_HTMLDocument
//#define PROGID "MSCAL.Calendar"
//#define PROGID "WordPad.Document.1"
//#define PROGID "SoftwareFX.ChartFX.20"

wxMozillaHtmlWin::wxMozillaHtmlWin(wxWindow * parent, wxWindowID id,
        const wxPoint& pos,
        const wxSize& size,
        long style,
        const wxString& name) :
    wxActiveX(parent, MPROGID, id, pos, size, style, name)
{
    SetupBrowser();
}


wxMozillaHtmlWin::~wxMozillaHtmlWin()
{
}

void wxMozillaHtmlWin::SetupBrowser()
{
	HRESULT hret;

	// Get IWebBrowser2 Interface
	hret = m_webBrowser.QueryInterface(IID_IWebBrowser2, m_ActiveX);
	assert(SUCCEEDED(hret));

	// web browser setup
	m_webBrowser->put_MenuBar(VARIANT_FALSE);
	m_webBrowser->put_AddressBar(VARIANT_FALSE);
	m_webBrowser->put_StatusBar(VARIANT_FALSE);
	m_webBrowser->put_ToolBar(VARIANT_FALSE);

	m_webBrowser->put_RegisterAsBrowser(VARIANT_TRUE);
	m_webBrowser->put_RegisterAsDropTarget(VARIANT_TRUE);

    m_webBrowser->Navigate( L"about:blank", NULL, NULL, NULL, NULL );
}


void wxMozillaHtmlWin::SetEditMode(bool seton)
{
    m_bAmbientUserMode = ! seton;
    AmbientPropertyChanged(DISPID_AMBIENT_USERMODE);
};

bool wxMozillaHtmlWin::GetEditMode()
{
    return ! m_bAmbientUserMode;
};


void wxMozillaHtmlWin::SetCharset(wxString charset)
{
	// HTML Document ?
	IDispatch *pDisp = NULL;
	HRESULT hret = m_webBrowser->get_Document(&pDisp);
	wxAutoOleInterface<IDispatch> disp(pDisp);

	if (disp.Ok())
	{
		wxAutoOleInterface<IHTMLDocument2> doc(IID_IHTMLDocument2, disp);
		if (doc.Ok())
            doc->put_charset((BSTR) (const wchar_t *) charset.wc_str(wxConvUTF8));
			//doc->put_charset((BSTR) wxConvUTF8.cMB2WC(charset).data());
	};
};

void wxMozillaHtmlWin::LoadUrl(const wxString& url)
{
	VARIANTARG navFlag, targetFrame, postData, headers;
	navFlag.vt = VT_EMPTY;
	navFlag.vt = VT_I2;
	navFlag.iVal = navNoReadFromCache;
	targetFrame.vt = VT_EMPTY;
	postData.vt = VT_EMPTY;
	headers.vt = VT_EMPTY;

	HRESULT hret = 0;
	hret = m_webBrowser->Navigate((BSTR) (const wchar_t *) url.wc_str(wxConvUTF8),
		&navFlag, &targetFrame, &postData, &headers);
};

bool  wxMozillaHtmlWin::LoadString(wxString html)
{
    char *data = NULL;
    size_t len = html.length();
#ifdef UNICODE
    len *= 2;
#endif
    data = (char *) malloc(len);
    memcpy(data, html.c_str(), len);
	return LoadStream(new wxOwnedMemInputStream(data, len));
};

bool wxMozillaHtmlWin::LoadStream(IStreamAdaptorBase *pstrm)
{
	// need to prepend this as poxy MSHTML will not recognise a HTML comment
	// as starting a html document and treats it as plain text
	// Does nayone know how to force it to html mode ?
	pstrm->prepend = "<html>";

	// strip leading whitespace as it can confuse MSHTML
	wxAutoOleInterface<IStream>	strm(pstrm);

    // Document Interface
    IDispatch *pDisp = NULL;
    HRESULT hret = m_webBrowser->get_Document(&pDisp);
	if (! pDisp)
		return false;
	wxAutoOleInterface<IDispatch> disp(pDisp);


	// get IPersistStreamInit
    wxAutoOleInterface<IPersistStreamInit>
		pPersistStreamInit(IID_IPersistStreamInit, disp);

    if (pPersistStreamInit.Ok())
    {
        HRESULT hr = pPersistStreamInit->InitNew();
        if (SUCCEEDED(hr))
            hr = pPersistStreamInit->Load(strm);

		return SUCCEEDED(hr);
    }
	else
	    return false;
};

bool  wxMozillaHtmlWin::LoadStream(istream *is)
{
	// wrap reference around stream
    IStreamAdaptor *pstrm = new IStreamAdaptor(is);
	pstrm->AddRef();

    return LoadStream(pstrm);
};

bool wxMozillaHtmlWin::LoadStream(wxInputStream *is)
{
	// wrap reference around stream
    IwxStreamAdaptor *pstrm = new IwxStreamAdaptor(is);
	pstrm->AddRef();

    return LoadStream(pstrm);
};


bool wxMozillaHtmlWin::GoBack()
{
    HRESULT hret = 0;
    hret = m_webBrowser->GoBack();
    return hret == S_OK;
}

bool wxMozillaHtmlWin::GoForward()
{
    HRESULT hret = 0;
    hret = m_webBrowser->GoForward();
    return hret == S_OK;
}

bool wxMozillaHtmlWin::GoHome()
{
    try
    {
        CallMethod(wxT("GoHome"));
        return true;
    }
    catch(exception&)
    {
        return false;
    };

  /*
   HRESULT hret = 0;
   hret = m_webBrowser->GoHome();
   return hret == S_OK;
  */
}

bool wxMozillaHtmlWin::GoSearch()
{
    HRESULT hret = 0;
    hret = m_webBrowser->GoSearch();
    return hret == S_OK;
}

/// bool wxMozillaHtmlWin::Refresh(wxMozillaHtmlRefreshLevel level)
bool wxMozillaHtmlWin::Refresh(int level)
{
    VARIANTARG levelArg;
    HRESULT hret = 0;

    levelArg.vt = VT_I2;
    levelArg.iVal = level;
    hret = m_webBrowser->Refresh2(&levelArg);
    return hret == S_OK;
}

bool wxMozillaHtmlWin::Stop()
{
    HRESULT hret = 0;
    hret = m_webBrowser->Stop();
    return hret == S_OK;
}


///////////////////////////////////////////////////////////////////////////////


wxString wxMozillaHtmlWin::GetStringSelection(bool asHTML)
{
	wxAutoOleInterface<IHTMLTxtRange> tr(GetSelRange(m_oleObject));
    if (! tr)
    	return wxT("");

    BSTR text = NULL;
    HRESULT hr = E_FAIL;

	if (asHTML)
		hr = tr->get_htmlText(&text);
	else
		hr = tr->get_text(&text);
    if (hr != S_OK)
    	return wxT("");

    wxString s = text;
    SysFreeString(text);

    return s;
};

wxString wxMozillaHtmlWin::GetText(bool asHTML)
{
	if (! m_webBrowser.Ok())
		return wxT("");

	// get document dispatch interface
	IDispatch *iDisp = NULL;
    HRESULT hr = m_webBrowser->get_Document(&iDisp);
    if (hr != S_OK)
    	return wxT("");

	// Query for Document Interface
    wxAutoOleInterface<IHTMLDocument2> hd(IID_IHTMLDocument2, iDisp);
    iDisp->Release();

    if (! hd.Ok())
		return wxT("");

	// get body element
	IHTMLElement *_body = NULL;
	hd->get_body(&_body);
	if (! _body)
		return wxT("");
	wxAutoOleInterface<IHTMLElement> body(_body);

	// get inner text
    BSTR text = NULL;
    hr = E_FAIL;

	if (asHTML)
		hr = body->get_innerHTML(&text);
	else
		hr = body->get_innerText(&text);
    if (hr != S_OK)
    	return wxT("");

    wxString s = text;
    SysFreeString(text);

    return s;
};

void wxMozillaHtmlWin::Print(bool WithPrompt)
{
  tagVARIANT vIn, vOut;

  if (WithPrompt) {
    m_webBrowser->ExecWB(
    OLECMDID_PRINT,
    OLECMDEXECOPT_PROMPTUSER ,
    &vIn, &vOut
    );
  }
  else {
    m_webBrowser->ExecWB(
    OLECMDID_PRINT,
    OLECMDEXECOPT_DONTPROMPTUSER ,
    &vIn, &vOut
    );
  }
}

void wxMozillaHtmlWin::PrintPreview()
{
  tagVARIANT vIn, vOut;

  m_webBrowser->ExecWB(
  OLECMDID_PRINTPREVIEW,
  OLECMDEXECOPT_DONTPROMPTUSER ,
  &vIn, &vOut
  );

}

