/* $Id$ */

/* TODO: make these dynamic instead */
/* max number of code pages */
#define MULTILANGUAGE_XS_NSCORES 32

/* max number of code pages */
#define MULTILANGUAGE_XS_DCPS    128

#define CreateMlang(p, iid) CoCreateInstance(&CLSID_CMultiLanguage, NULL, CLSCTX_ALL, iid, (VOID**)p)

#define VC_EXTRALEAN
#define CINTERFACE
#define COBJMACROS

#include <windows.h>
#include <mlang.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* wchar2sv(LPCWSTR lpS, UINT nLen)
{
    SV* result;
    unsigned int i = 0;
    U8 temp[1024 * UTF8_MAXLEN + 1];
    U8* d;
    
    if (nLen == 0)
      nLen = wcslen(lpS);

    // faster version for short strings
    if (nLen < 1024){
        d = temp;
        for (i = 0; i < nLen; ++i)
            d = uvuni_to_utf8_flags(d, lpS[i], 0);
        result = newSVpvn((const char*)temp, d - temp);
    } else {
        result = newSVpvn("", 0);
        for (i = 0; i < nLen; ++i) {
            d = (U8 *)SvGROW(result, SvCUR(result) + UTF8_MAXLEN + 1);
            d = uvuni_to_utf8_flags(d + SvCUR(result), lpS[i], 0); 
            SvCUR_set(result, d - (U8 *)SvPVX(result));
        }
    }

    SvUTF8_on(result);
    return result;}

LPWSTR sv2wchar(SV* sv, UINT* len)
{
    LPWSTR lpNew;
    STRLEN svlen;
    LPSTR lpOld;
    int nRequired;
    
    /* TODO: This could use a replacement */
    
    if (!sv)
      return NULL;
      
    if (!SvUTF8(sv))
    {
        /* warn("non-utf8 data in sv2wchar\n"); */
    }
    
    if(!len)
      return NULL;
    
    *len = 0;
    
    /* upgrade to utf-8 if necessary */
    lpOld = SvPVutf8(sv, svlen);
    
    if (!svlen)
    {
        New(42, lpNew, 1, WCHAR);
        lpNew[0] = 0;
        return lpNew;
    }

    nRequired = MultiByteToWideChar(65001, 0, lpOld, svlen, NULL, 0);
    
    if (!nRequired)
    {
        warn("Unexpected result from MultiByteToWideChar\n");
        return NULL;
    }

    New(42, lpNew, nRequired + 1, WCHAR);

    if (!lpNew)
    {
        warn("Insufficient memory\n");
        return NULL;
    }
    
    /* null-terminate string */
    lpNew[nRequired] = 0;

    if (!MultiByteToWideChar(65001, 0, lpOld, svlen, lpNew, nRequired))
    {
        warn("MultiByteToWideChar failed\n");
        Safefree(lpNew);
        return NULL;
    }
    
    /* set length */
    *len = nRequired;
    
    return lpNew;
}

HV*
MimeCpInfo2Sv(PMIMECPINFO pcpi) {
    HV* hv = newHV();
    
    hv_store(hv, "Flags",             5, newSVuv(pcpi->dwFlags), 0);
    hv_store(hv, "CodePage",          8, newSVuv(pcpi->uiCodePage), 0);
    hv_store(hv, "FamilyCodePage",   14, newSVuv(pcpi->uiFamilyCodePage), 0);
    hv_store(hv, "Description",      11, wchar2sv(pcpi->wszDescription, 0), 0);
    hv_store(hv, "WebCharset",       10, wchar2sv(pcpi->wszWebCharset, 0), 0);
    hv_store(hv, "HeaderCharset",    13, wchar2sv(pcpi->wszHeaderCharset, 0), 0);
    hv_store(hv, "BodyCharset",      11, wchar2sv(pcpi->wszBodyCharset, 0), 0);
    hv_store(hv, "FixedWidthFont",   14, wchar2sv(pcpi->wszFixedWidthFont, 0), 0);
    hv_store(hv, "ProportionalFont", 16, wchar2sv(pcpi->wszProportionalFont, 0), 0);
    hv_store(hv, "GDICharset",       10, newSViv(pcpi->bGDICharset), 0);

    return hv;
}

HV*
ScriptInfo2Sv(PSCRIPTINFO psi) {
    HV* hv = newHV();
    
    hv_store(hv, "ScriptId",          8, newSVuv(psi->ScriptId), 0);
    hv_store(hv, "CodePage",          8, newSVuv(psi->uiCodePage), 0);
    hv_store(hv, "Description",      11, wchar2sv(psi->wszDescription, 0), 0);
    hv_store(hv, "FixedWidthFont",   14, wchar2sv(psi->wszFixedWidthFont, 0), 0);
    hv_store(hv, "ProportionalFont", 16, wchar2sv(psi->wszProportionalFont, 0), 0);

    return hv;
}

HV*
Rfc1766Info2Sv(PRFC1766INFO pRfc1766Info) {
    HV* hv = newHV();
    
    hv_store(hv, "Lcid",        4, newSVuv(pRfc1766Info->lcid), 0);
    hv_store(hv, "Rfc1766",     7, wchar2sv(pRfc1766Info->wszRfc1766, 0), 0);
    hv_store(hv, "LocaleName", 10, wchar2sv(pRfc1766Info->wszLocaleName, 0), 0);

    return hv;
}

MODULE = Win32::MultiLanguage PACKAGE = Win32::MultiLanguage      

PROTOTYPES: DISABLE

BOOT:
    if (CoInitialize(NULL) != S_OK)
    {
        /* TODO: check whether this is the best thing to do */
        croak("CoInitialize failed\n");
        XSRETURN_NO;
    }

void
DetectInputCodepage(octets, ...)
    SV* octets

  PREINIT:
    DWORD dwFlag = MLDETECTCP_NONE;
    DWORD dwPrefWinCodePage = 0;
    CHAR* pSrcStr;
    INT cSrcSize;
    DetectEncodingInfo lpEncoding[MULTILANGUAGE_XS_NSCORES];
    INT nScores = MULTILANGUAGE_XS_NSCORES;
    STRLEN nOctets;
    HRESULT hr;
    int i;
    AV* av;
    IMultiLanguage2* p;

  PPCODE:

    if (items > 1)
        dwFlag = (DWORD)SvIV(ST(1));

    if (items > 2)
        dwPrefWinCodePage = (DWORD)SvIV(ST(2));
        
    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    pSrcStr = SvPV(octets, nOctets);
    cSrcSize = (INT)nOctets;

    /**/
    hr = IMultiLanguage2_DetectInputCodepage(p,
                                             dwFlag,
                                             dwPrefWinCodePage,
                                             pSrcStr,
                                             &cSrcSize,
                                             lpEncoding,
                                             &nScores);

    /* no longer needed */
    IMultiLanguage2_Release(p);

    if (hr == S_FALSE)
    {
        XSRETURN_EMPTY;
    }
    else if (hr == E_FAIL || hr != S_OK)
    {
        warn("An error occured while calling DetectInputCodepage\n");
        XSRETURN_EMPTY;
    }
    
    av = newAV();

    for (i = 0; i < nScores; ++i)
    {
        HV* hv = newHV();

        hv_store(hv, "LangID", 6, newSViv(lpEncoding[i].nLangID), 0);
        hv_store(hv, "CodePage", 8, newSViv(lpEncoding[i].nCodePage), 0);
        hv_store(hv, "DocPercent", 10, newSViv(lpEncoding[i].nDocPercent), 0);
        hv_store(hv, "Confidence", 10, newSViv(lpEncoding[i].nConfidence), 0);

        av_push(av, newRV_noinc((SV*)hv));
    }

    XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));

void
GetRfc1766FromLcid(Lcid = GetUserDefaultLCID())
    unsigned Lcid

  PREINIT:
    BSTR bstrRfc1766;
    HRESULT hr;
    IMultiLanguage2* p;
    SV* result;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }
    
    hr = IMultiLanguage2_GetRfc1766FromLcid(p, Lcid, &bstrRfc1766);
    IMultiLanguage2_Release(p);
    
    if (hr == E_INVALIDARG)
    {
        warn("One or more of the arguments are invalid.\n");
        XSRETURN_EMPTY;
    }
    else if (hr == E_FAIL || hr != S_OK || !bstrRfc1766)
    {
        XSRETURN_EMPTY;
    }
    
    result = wchar2sv(bstrRfc1766, 0);
    
    /*
      it is not documented that the caller is responsible for freeing the bstr
      but if this is not done here the application leaks memory, so we free it
    */
    SysFreeString(bstrRfc1766);
    XPUSHs(sv_2mortal(result));

void
GetCodePageInfo(CodePage, LangId)
    unsigned CodePage
    unsigned LangId

  PREINIT:
    MIMECPINFO cpi;
    IMultiLanguage2* p;
    HV* hv;
    HRESULT hr;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }
    
    hr = IMultiLanguage2_GetCodePageInfo(p, CodePage, LangId, &cpi);

    /* no longer needed */
    IMultiLanguage2_Release(p);

    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }

    hv = MimeCpInfo2Sv(&cpi);
    
    XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));

void
GetCodePageDescription(CodePage, Lcid = GetUserDefaultLCID())
    unsigned CodePage
    unsigned Lcid

  PREINIT:
    WCHAR lpWideCharStr[MAX_MIMECP_NAME];
    int cchWideChar = MAX_MIMECP_NAME;
    IMultiLanguage2* p;
    HRESULT hr;

  PPCODE:
  
    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetCodePageDescription(p, CodePage, Lcid, lpWideCharStr, cchWideChar);
    
    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }

    XPUSHs(sv_2mortal(wchar2sv(lpWideCharStr, 0)));
  
void
GetCharsetInfo(svCharset)
    SV* svCharset
    
  PREINIT:
    HV* hv;
    MIMECSETINFO csi;
    IMultiLanguage2* p;
    BSTR bstrCharset;
    UINT len;
    HRESULT hr;
    
  PPCODE:

    bstrCharset = (BSTR)sv2wchar(svCharset, &len);
    
    if (!bstrCharset)
    {
        warn("conversion to wide string failed\n");
        XSRETURN_EMPTY;
    }
    
    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetCharsetInfo(p, bstrCharset, &csi);

    /* no longer needed */
    Safefree(bstrCharset);
    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    hv = newHV();
    hv_store(hv, "CodePage",          8, newSVuv(csi.uiCodePage), 0);
    hv_store(hv, "InternetEncoding", 16, newSVuv(csi.uiInternetEncoding), 0);
    hv_store(hv, "Charset",           7, wchar2sv(csi.wszCharset, 0), 0);

    XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));

void
DetectOutboundCodePage(sv, ...)
    SV* sv

  PREINIT:
    DWORD dwFlags = 0;
    LPWSTR lpWideCharStr = NULL;
    UINT cchWideChar = 0;
    UINT* puiPreferredCodePages = NULL;
    UINT nPreferredCodePages = 0;
    UINT puiDetectedCodePages[MULTILANGUAGE_XS_DCPS];
    UINT nDetectedCodePages = MULTILANGUAGE_XS_DCPS;
    LPWSTR wcSpecialChar = NULL;
    HRESULT hr;
    IMultiLanguage3* p;
    UINT i;
    
  PPCODE:
  
    if (items > 1)
        dwFlags = (DWORD)SvIV(ST(1));

    if (items > 2)
    {
        warn("Third parameter not yet implemented\n");
    }
    
    lpWideCharStr = sv2wchar(sv, &cchWideChar);
    
    if (!lpWideCharStr)
    {
        warn("Conversion to wide string failed\n");
        XSRETURN_EMPTY;
    }
    
    if (CreateMlang(&p, &IID_IMultiLanguage3)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage3_DetectOutboundCodePage(p,
                                                dwFlags,
                                                lpWideCharStr,
                                                cchWideChar, 
                                                puiPreferredCodePages, 
                                                nPreferredCodePages,
                                                puiDetectedCodePages,
                                                &nDetectedCodePages,
                                                wcSpecialChar);

    /* no longer needed */
    Safefree(lpWideCharStr);
    IMultiLanguage3_Release(p);

    if (hr != S_OK || !nDetectedCodePages)
    {
        XSRETURN_EMPTY;
    }
    
    for (i = 0; i < nDetectedCodePages; ++i)
    {
        XPUSHs(sv_2mortal(newSViv(puiDetectedCodePages[i])));
    }

SV*
IsConvertible(SrcCodePage, DstCodePage)
    unsigned SrcCodePage
    unsigned DstCodePage

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;

  CODE:
    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_IsConvertible(p, SrcCodePage, DstCodePage);

    IMultiLanguage2_Release(p);

    if (hr == S_FALSE)
        XSRETURN_NO;
        
    if (hr == S_OK)
        XSRETURN_YES;
        
    XSRETURN_UNDEF;

void
GetRfc1766Info(Lcid = GetUserDefaultLCID(), LangId = GetUserDefaultLangID())
    unsigned Lcid
    unsigned short LangId

  PREINIT:
    RFC1766INFO Rfc1766Info;
    HRESULT hr;
    HV* hv;
    IMultiLanguage2* p;
    
  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetRfc1766Info(p, Lcid, LangId, &Rfc1766Info);

    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    hv = Rfc1766Info2Sv(&Rfc1766Info);
    
    XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));

void
GetLcidFromRfc1766(svRfc1766)
    SV* svRfc1766

  PREINIT:
    LCID Locale;
    BSTR bstrRfc1766;
    HRESULT hr;
    IMultiLanguage2* p;
    UINT len;
  
  PPCODE:
  
    bstrRfc1766 = sv2wchar(svRfc1766, &len);
    
    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetLcidFromRfc1766(p, &Locale, bstrRfc1766);

    IMultiLanguage2_Release(p);

    Safefree(bstrRfc1766);
    
    if (hr != S_FALSE && hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    XPUSHs(sv_2mortal(newSViv( Locale )));
    XPUSHs(sv_2mortal(newSViv( hr == S_FALSE )));

void
GetFamilyCodePage(CodePage)
    unsigned CodePage

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    UINT uiFamilyCodePage;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetFamilyCodePage(p, CodePage, &uiFamilyCodePage);

    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    XPUSHs(sv_2mortal(newSViv( uiFamilyCodePage )));

void
GetNumberOfCodePageInfo()

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    UINT uiCodePage = 0;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetNumberOfCodePageInfo(p, &uiCodePage);

    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    XPUSHs(sv_2mortal(newSViv( uiCodePage )));

void
EnumCodePages(Flags = 0, LangId = GetUserDefaultLangID())
  unsigned Flags;
  unsigned short LangId;

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    IEnumCodePage* pEnumCp;
    ULONG pceltFetched;
    MIMECPINFO cpi;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_EnumCodePages(p, Flags, LangId, &pEnumCp);
    IMultiLanguage2_Release(p);
    
    if (hr != S_OK) {
      warn("Failed to get enumerator object\n");
      XSRETURN_EMPTY;
    }

    while (S_OK == IEnumCodePage_Next(pEnumCp, 1, &cpi, &pceltFetched)) {
      HV* svInfo = MimeCpInfo2Sv(&cpi);
      XPUSHs(sv_2mortal(newRV_noinc((SV*)svInfo)));
    }

    IEnumCodePage_Release(pEnumCp);

void
EnumScripts(Flags = 0, LangId = GetUserDefaultLangID())
  unsigned Flags;
  unsigned short LangId;

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    IEnumScript* pEnumScript;
    ULONG pceltFetched;
    SCRIPTINFO si;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_EnumScripts(p, Flags, LangId, &pEnumScript);
    IMultiLanguage2_Release(p);
    
    if (hr != S_OK) {
      warn("Failed to get enumerator object\n");
      XSRETURN_EMPTY;
    }

    while (S_OK == IEnumScript_Next(pEnumScript, 1, &si, &pceltFetched)) {
      HV* svInfo = ScriptInfo2Sv(&si);
      XPUSHs(sv_2mortal(newRV_noinc((SV*)svInfo)));
    }

    IEnumScript_Release(pEnumScript);

void
EnumRfc1766(LangId = GetUserDefaultLangID())
  unsigned short LangId

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    IEnumRfc1766* pEnumRfc1766;
    ULONG pceltFetched;
    RFC1766INFO ri;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_EnumRfc1766(p, LangId, &pEnumRfc1766);
    IMultiLanguage2_Release(p);
    
    if (hr != S_OK) {
      warn("Failed to get enumerator object\n");
      XSRETURN_EMPTY;
    }

    while (S_OK == IEnumRfc1766_Next(pEnumRfc1766, 1, &ri, &pceltFetched)) {
      HV* svInfo = Rfc1766Info2Sv(&ri);
      XPUSHs(sv_2mortal(newRV_noinc((SV*)svInfo)));
    }

    IEnumRfc1766_Release(pEnumRfc1766);

void
GetNumberOfScripts()

  PREINIT:
    HRESULT hr;
    IMultiLanguage2* p;
    UINT nScripts = 0;

  PPCODE:

    if (CreateMlang(&p, &IID_IMultiLanguage2)) {
        warn("CoCreateInstance failed\n");
        XSRETURN_EMPTY;
    }

    hr = IMultiLanguage2_GetNumberOfScripts(p, &nScripts);

    IMultiLanguage2_Release(p);
    
    if (hr != S_OK)
    {
        XSRETURN_EMPTY;
    }
    
    XPUSHs(sv_2mortal(newSViv( nScripts )));

void
Transcode(CodePageIn, CodePageOut, String, Flags)
  unsigned CodePageIn
  unsigned CodePageOut
  SV* String
  unsigned Flags

  PREINIT:
    HRESULT hr;
    IMLangConvertCharset* p;
    BYTE* pSrcStr;
    BYTE* pDstStr = NULL;
    UINT uiDstSize = 0;
    UINT uiSrcSize;
    SV* Result;

  PPCODE:

    if (SvUTF8(String) && CodePageIn != CP_UTF8) {
      /* warn("Request to transcode UTF-8 string from non-UTF-8 code page\n"); */
    }
    
    hr = CoCreateInstance(&CLSID_CMLangConvertCharset,
      NULL, CLSCTX_ALL, &IID_IMLangConvertCharset, (VOID**)&p);

    if (hr != S_OK) {
      warn("CoCreateInstance failed\n");
      XSRETURN_EMPTY;
    }
    
    pSrcStr = SvPV(String, uiSrcSize);

    hr = IMLangConvertCharset_Initialize(p, CodePageIn, CodePageOut, Flags);
    
    if (hr == S_OK)
      /* While this is not documented, if uiDstSize is zero, it will receive */
      /* the required length in bytes for the conversion to succeed (I hope) */
      hr = IMLangConvertCharset_DoConversion(p, pSrcStr, &uiSrcSize, pDstStr, &uiDstSize);

    if (hr != S_OK) {
      IMLangConvertCharset_Release(p);
      croak("Cannot convert between code pages\n");
    }

    Result = newSVpv("", 0);
    pDstStr = SvGROW(Result, uiDstSize);

    hr = IMLangConvertCharset_DoConversion(p, pSrcStr, &uiSrcSize, pDstStr, &uiDstSize);

    IMLangConvertCharset_Release(p);

    if (hr != S_OK) {
      SvREFCNT_dec(Result);
      XSRETURN_EMPTY;
    }

    SvCUR_set(Result, uiDstSize);
    
    if (CodePageOut == CP_UTF8)
      SvUTF8_on( Result );

    XPUSHs(sv_2mortal( Result ));

void
END()
  CODE:
    CoUninitialize();
    XSRETURN_YES; /* TODO: ... */

