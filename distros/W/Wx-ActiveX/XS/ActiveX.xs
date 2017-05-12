############################################################################
## Name:        ActiveX.xs
## Purpose:     XS for Wx::ActiveX
## Author:      Graciliano M. P.
## Modified by:
## SVN-ID:      $Id: ActiveX.xs 2364 2008-04-10 04:21:35Z mdootson $
## Copyright:   (c) 2002 - 2007 Graciliano M. P. and Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

MODULE=Wx PACKAGE=Wx::ActiveX

SV*
XS_convert_isa(obj , klass)
    SV* obj
    const char* klass
  CODE:
    HV* stash = gv_stashpv(klass , 1);

    // already an hash ref, only needs to (re)bless it in
    // the correct class
    if (SvROK(obj) && SvTYPE(SvRV(obj)) >= SVt_PVHV) {
        sv_bless(obj, stash);
        SvREFCNT_inc(obj); // for SV* typemap
        RETVAL = obj;
    }
    else {
        HV* hv = newHV();
    
        RETVAL = newRV_noinc((SV*)hv);
        sv_bless(RETVAL, stash);
        void* cpp_obj;
    
        if (SvROK(obj))
            cpp_obj = wxPli_detach_object( aTHX_ obj );
        else
            cpp_obj = (void*)SvIV(obj);
    
        wxPli_attach_object( aTHX_ RETVAL, cpp_obj );
    }
  OUTPUT: RETVAL

#ifdef BUILD_SENDKEYS_HACKS
 
void
XS_SendKeysToActiveWindow( ... )
  PREINIT:
    int* vkeys;
    int i;
    int x = 0;
    int records;
  CODE:
    vkeys = new int[items];
    for( i = 0; i < items; ++i )
    {
      vkeys[i] = SvIV( ST(i) );
    }
    
    records = items * 2;
    
    INPUT input[records];
    memset(input, 0, sizeof(input));
    
    for( i = 0; i < items; ++i )
    {
        input[x].type = INPUT_KEYBOARD;
        input[x].ki.wVk = vkeys[i];
        input[x].ki.dwFlags = 0;
        input[x].ki.time = 0;
        input[x].ki.dwExtraInfo = 0;
        
        ++x;
    }
    
    for( i = items; i > 0; --i )
    {
        input[x].type = INPUT_KEYBOARD;
        input[x].ki.wVk = vkeys[i];
        input[x].ki.dwFlags = KEYEVENTF_KEYUP;
        input[x].ki.time = 0;
        input[x].ki.dwExtraInfo = 0;
        
        ++x;
    }
    
    SendInput(records, input, sizeof(INPUT));
    delete[] vkeys;
    
void
XS_SendRightClickToActiveWindow()
  CODE:
    
    INPUT input[2];
    memset(input, 0, sizeof(input));
    
    input[0].type = INPUT_MOUSE;
    input[0].mi.dx = 0;
    input[0].mi.dy = 0;
    input[0].mi.mouseData = MOUSEEVENTF_RIGHTDOWN;
    input[0].mi.dwFlags = 0;
    input[0].mi.time = 0;
    input[0].mi.dwExtraInfo = 0;
    
    input[1].type = INPUT_MOUSE;
    input[1].mi.dx = 0;
    input[1].mi.dy = 0;
    input[1].mi.mouseData = MOUSEEVENTF_RIGHTUP;
    input[1].mi.dwFlags = 0;
    input[1].mi.time = 0;
    input[1].mi.dwExtraInfo = 0;
        
    SendInput(2, input, sizeof(INPUT));

void
XS_SendLeftClickToActiveWindow()
  CODE:
    
    INPUT input[2];
    memset(input, 0, sizeof(input));
    
    input[0].type = INPUT_MOUSE;
    input[0].mi.dx = 0;
    input[0].mi.dy = 0;
    input[0].mi.mouseData = MOUSEEVENTF_LEFTDOWN;
    input[0].mi.dwFlags = 0;
    input[0].mi.time = 0;
    input[0].mi.dwExtraInfo = 0;
    
    input[1].type = INPUT_MOUSE;
    input[1].mi.dx = 0;
    input[1].mi.dy = 0;
    input[1].mi.mouseData = MOUSEEVENTF_LEFTUP;
    input[1].mi.dwFlags = 0;
    input[1].mi.time = 0;
    input[1].mi.dwExtraInfo = 0;
        
    SendInput(2, input, sizeof(INPUT));


#endif

wxActiveX*
wxActiveX::new( parent, progId , id, pos = wxDefaultPosition, size = wxDefaultSize, style = 0, name = wxPanelNameStr )
    wxWindow* parent
    wxString progId
    wxWindowID id
    wxPoint pos
    wxSize size
    long style
    wxString name
  CODE:
    RETVAL = new wxPliActiveX( CLASS, parent, progId, id, pos, size, style, name );
  OUTPUT:
    RETVAL    

void
wxActiveX::Invoke(name , ...)
    wxString name
  PREINIT:
    wxVariant args, ret;
    int i, max;
  PPCODE:
    args.NullList();

    for(i = 2; i < items; i++){
        wxString argx ;
        WXSTRING_INPUT(argx, wxString, ST(i) );
        args.Append( wxVariant(argx) );
    }
    
    ret = THIS->CallMethod(name , args) ;
    max = ret.GetCount() ;
      
    for(i = 0; i < max; i++) {
        wxString retx = ret[i].GetString() ;
#if wxUSE_UNICODE
        SV* tmp = sv_2mortal( newSVpv( retx.mb_str(wxConvUTF8), 0 ) );
        SvUTF8_on( tmp );
        PUSHs( tmp );
#else
        PUSHs( sv_2mortal( newSVpv( CHAR_P retx.c_str(), 0 ) ) );
#endif
    }
/*
void
wxActiveX::ActivateOLEWindowDirect( activate = 1 )
    bool activate
*/

int
wxActiveX::GetMethodCount()

wxString
wxActiveX::GetMethodName(idx)
    int idx

int
wxActiveX::GetMethodArgCount(idx)
    int idx

wxString
wxActiveX::GetMethodArgName(idx , argx)
    int idx
    int argx

int
wxActiveX::GetEventCount()

wxString
wxActiveX::GetEventName(idx)
    int idx
    
int
wxActiveX::GetPropCount()

wxString
wxActiveX::GetPropName(idx)
    int idx

wxString
wxActiveX::PropType(name)
    wxString name

wxString
wxActiveX::PropVal(name)
    wxString name

void    
wxActiveX::PropSetBool(name , val)
    wxString name
    bool val
    
void    
wxActiveX::PropSetInt(name , val)
    wxString name
    long val

void    
wxActiveX::PropSetString(name , val)
    wxString name
    wxString val

void
wxActiveX::GetOLE()
CODE:
{
    typedef SV* (*MYPROC)(pTHX_ HV *, IDispatch *, SV *);
    HMODULE hmodule;
    MYPROC pCreatePerlObject;
    IDispatch * pDispatch;
  
    ST(0) = &PL_sv_undef;
    // Fix for packagers - as per Win32::GUI::AxWindow
    
    // Try to find OLE.dll
    hmodule = GetModuleHandle(_T("OLE"));
    if (hmodule == 0) {
        // Try to find using Dynaloader
        AV* av_modules = get_av("DynaLoader::dl_modules", FALSE);
        AV* av_librefs = get_av("DynaLoader::dl_librefs", FALSE);
        if (av_modules && av_librefs) {
            // Look at Win32::OLE package
            for (I32 i = 0; i < av_len(av_modules); i++) {
                SV** sv = av_fetch(av_modules, i, 0);
                if (sv && SvPOK (*sv) &&
                    strEQ(SvPV_nolen(*sv), "Win32::OLE")) {
                    sv = av_fetch(av_librefs, i, 0);
                    hmodule = (HMODULE) (sv && SvIOK (*sv) ? SvIV(*sv) : 0);
                    break;
                }
            }
        }
    }
    
    if (hmodule != 0)
    {
        pCreatePerlObject = (MYPROC) GetProcAddress(hmodule, "CreatePerlObject");
        if (pCreatePerlObject != 0)  {
            HV *stash = gv_stashpv("Win32::OLE", TRUE);
            pDispatch = THIS->GetOLEDispatch();
            pDispatch->AddRef();
            ST(0) = (pCreatePerlObject)(aTHX_ stash, pDispatch, NULL);
        }
    }
}


######### EVENTS:

MODULE=Wx PACKAGE=Wx::ActiveXEvent

wxActiveXEvent*
wxActiveXEvent::new()

wxString
wxActiveXEvent::EventName()

int
wxActiveXEvent::ParamCount()

wxString
wxActiveXEvent::ParamType(idx)
    int idx

wxString
wxActiveXEvent::ParamName(idx)
    int idx
    
wxString
wxActiveXEvent::ParamVal(idx)
    int idx
    
void    
wxActiveXEvent::ParamSetBool(idx , val)
    int idx
    bool val
    
void    
wxActiveXEvent::ParamSetInt(idx , val)
    int idx
    long val
    
void    
wxActiveXEvent::ParamSetString(idx , val)
    int idx
    wxString val

wxEventType
RegisterActiveXEvent( eventName )
    wxChar* eventName

#  //FIXME//tricky
#if defined(__WXMSW__)
#undef XS
#define XS( name ) WXXS( name )
#endif

MODULE=Wx__ActiveX


