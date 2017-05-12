/////////////////////////////////////////////////////////////////////////////
// Name:        cpp/activex.h
// Purpose:     c++ wrapper for wxActiveX
// Author:      Mark Dootson.
// SVN-ID:      $Id: PlActiveX.h 2530 2009-02-12 16:51:45Z mdootson $
// Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

class wxPliActiveX:public wxActiveX
{
    public:

        static wxPliClassInfo ms_classInfo;
        virtual wxClassInfo *GetClassInfo() const { return &ms_classInfo; }
        wxPliVirtualCallback m_callback;
        wxPliActiveX( const char* package, wxWindow* _arg1, const wxString& _arg2, wxWindowID _arg3,
            const wxPoint& _arg4, const wxSize& _arg5, long _arg6, const wxString& _arg7)
        : wxActiveX( _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7 ), m_callback( "Wx::ActiveX" )
        {
            m_callback.SetSelf( wxPli_make_object( this, package ), true );
        }

};

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPliActiveX,
                               wxActiveX );


class wxPliIEHtmlWin:public wxIEHtmlWin
{
    public:
        static wxPliClassInfo ms_classInfo;
        virtual wxClassInfo *GetClassInfo() const { return &ms_classInfo; }
        wxPliVirtualCallback m_callback;
        wxPliIEHtmlWin( const char* package, wxWindow* _arg1, wxWindowID _arg2,
            const wxPoint& _arg3, const wxSize& _arg4, long _arg5, const wxString& _arg6)
        : wxIEHtmlWin( _arg1, _arg2, _arg3, _arg4, _arg5, _arg6 ), m_callback( "Wx::IEHtmlWin" )
        {
            m_callback.SetSelf( wxPli_make_object( this, package ), true );
        }

};

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPliIEHtmlWin,
                               wxIEHtmlWin );


class wxPliMozillaHtmlWin:public wxMozillaHtmlWin
{
    public:
        static wxPliClassInfo ms_classInfo;
        virtual wxClassInfo *GetClassInfo() const { return &ms_classInfo; }
        wxPliVirtualCallback m_callback;
        wxPliMozillaHtmlWin( const char* package, wxWindow* _arg1, wxWindowID _arg2,
            const wxPoint& _arg3, const wxSize& _arg4, long _arg5, const wxString& _arg6)
        : wxMozillaHtmlWin( _arg1, _arg2, _arg3, _arg4, _arg5, _arg6 ), m_callback( "Wx::MozillaHtmlWin" )
        {
            m_callback.SetSelf( wxPli_make_object( this, package ), true );
        }

};

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPliMozillaHtmlWin,
                               wxMozillaHtmlWin );

// Local variables: //
// mode: c++ //
// End: //
