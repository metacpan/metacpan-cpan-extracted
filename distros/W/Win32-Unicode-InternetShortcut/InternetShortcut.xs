#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "InternetShortcut.h"

/* Copied from http://www.ooportal.com/basic-com-programming/module3/win32-apiFunction-formatMessage.php */
#define EBUF_SIZ 2048
static void
ComErrorMsg(int croak_on_error, char *from, HRESULT hr) {
    TCHAR ebuf[EBUF_SIZ];

    if (! croak_on_error) {
        return;
    }

    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
                  NULL,
                  hr,
                  0,
                  ebuf,
                  EBUF_SIZ * sizeof(TCHAR),
                  NULL);

    croak("%s, %s", from, ebuf);
}

/* Convert SV to wide character string.  The return value must be
 * freed using Safefree().
 * (Taken from Win32.xs)
 */
static WCHAR*
sv_to_wstr(pTHX_ SV *sv)
{
    DWORD wlen;
    WCHAR *wstr;
    STRLEN len;
    char *str = SvPV(sv, len);
    UINT cp = SvUTF8(sv) ? CP_UTF8 : CP_ACP;

    wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), NULL, 0);
    New(0, wstr, wlen, WCHAR);
    MultiByteToWideChar(cp, 0, str, (int)(len+1), wstr, wlen);

    return wstr;
}

/* Convert wide character string to mortal SV.  Use UTF8 encoding
 * if the string cannot be represented in the system codepage.
 * (Taken from Win32.xs)
 */
static SV *
wstr_to_sv(pTHX_ WCHAR *wstr)
{
    int wlen = (int)wcslen(wstr)+1;
    BOOL use_default = FALSE;
    int len = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, wstr, wlen, NULL, 0, NULL, NULL);
    SV *sv = sv_2mortal(newSV(len));

    len = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, wstr, wlen, SvPVX(sv), len, NULL, &use_default);
    if (use_default) {
        len = WideCharToMultiByte(CP_UTF8, 0, wstr, wlen, NULL, 0, NULL, NULL);
        sv_grow(sv, len);
        len = WideCharToMultiByte(CP_UTF8, 0, wstr, wlen, SvPVX(sv), len, NULL, NULL);
        SvUTF8_on(sv);
    }
    /* Shouldn't really ever fail since we ask for the required length first, but who knows... */
    if (len) {
        SvPOK_on(sv);
        SvCUR_set(sv, len-1);
    }
    return sv;
}

DWORD
constant(char *name)
{
    errno = 0;
    switch (*name) {
        case 'A':
            break;
        case 'B':
            break;
        case 'C':
            if (strEQ(name, "COINIT_APARTMENTTHREADED")) {
                return COINIT_APARTMENTTHREADED;
            } else if (strEQ(name, "COINIT_MULTITHREADED")) {
                return COINIT_MULTITHREADED;
            } else if (strEQ(name, "COINIT_DISABLE_OLE1DDE")) {
                return COINIT_DISABLE_OLE1DDE;
            } else if (strEQ(name, "COINIT_SPEED_OVER_MEMORY")) {
                return COINIT_SPEED_OVER_MEMORY;
            }
            break;
        case 'D':
            break;
        case 'E':
            break;
        case 'F':
            break;
        case 'G':
            break;
        case 'H':
            break;
        case 'I':
            break;
        case 'J':
            break;
        case 'K':
            break;
        case 'L':
            break;
        case 'M':
            break;
        case 'N':
            break;
        case 'O':
            break;
        case 'P':
            break;
        case 'Q':
            break;
        case 'R':
            break;
        case 'S':
            break;
        case 'T':
            break;
        case 'U':
            break;
        case 'V':
            break;
        case 'W':
            break;
        case 'X':
            break;
        case 'Y':
            break;
        case 'Z':
            break;
    }
    errno = EINVAL;
    return 0;

 not_there:
    errno = ENOENT;
    return 0;
}

HRESULT
_set_curfile_and_load(hash, ifile, wpath, wabsPath, croak_on_error)
     HV * hash;
     WCHAR * wpath;
     WCHAR * wabsPath;
     IPersistFile * ifile;
     int croak_on_error;
{
      HRESULT hres;
      LPOLESTR pszFileName;
      LPMALLOC pMalloc = NULL;

      if (_wfullpath(wabsPath, wpath, MY_MAX_PATHW) == NULL) {
	ComErrorMsg(croak_on_error,"_wfullpath (_set_curfile_and_load)", E_FAIL);
	return(S_FALSE);
      }

      HASH_STORE(hash, HK_PATH, SvREFCNT_inc(wstr_to_sv(aTHX_ wpath)));
      HASH_STORE(hash, HK_FULLPATH, SvREFCNT_inc(wstr_to_sv(aTHX_ wabsPath)));

      if ((hres = CoGetMalloc(1, &pMalloc)) != S_OK) {
	ComErrorMsg(croak_on_error,"CoGetMalloc (_set_curfile_and_load)", hres);
	return(hres);
      }

      hres = IPersistFile_GetCurFile(ifile, &pszFileName);
      if ((hres != S_OK) || (wcscmp(pszFileName, wabsPath) != 0)) {
	hres = IPersistFile_Load(ifile, wabsPath, _STGM_SHARE_READWRITE);
	if (hres != S_OK) {
	  ComErrorMsg(croak_on_error, "IPersistFile_Load (_set_curfile_and_load)", hres);
	  IMalloc_Free(pMalloc, pszFileName);
	  return(hres);
	}
      }

      IMalloc_Free(pMalloc, pszFileName);

      return(S_OK);
}

HRESULT
_read_ini(wpath, wini_key, hash, hash_key_e)
     WCHAR * wpath;
     WCHAR * wini_key;
     HV *   hash;
     hk_e hash_key_e;
{
    WCHAR wszBuf[MY_MAX_PATHW];
    DWORD dres;

    dres = GetPrivateProfileStringW(
                                    L"InternetShortcut",
                                    wini_key,
                                    L"",
                                    wszBuf,
                                    MY_MAX_PATHW,
                                    wpath
                                    );

    if (dres <= 0) {
        HASH_STORE(hash, hash_key_e, newSVsv(&PL_sv_undef));
        return(S_FALSE);
    }

    HASH_STORE(hash, hash_key_e, SvREFCNT_inc(wstr_to_sv(aTHX_ wszBuf)));

    return(S_OK);
}

HRESULT
_write_ini(wpath, wini_key, hash, hash_key_e, croak_on_error)
     WCHAR * wpath;
     WCHAR * wini_key;
     HV *   hash;
     hk_e hash_key_e;
     int croak_on_error;
{
    WCHAR *wszBuf = NULL;
    DWORD dres;

    HASH_GET(hash, hash_key_e, wszBuf);
    if (wszBuf != NULL) {
        dres = WritePrivateProfileStringW(
                                          L"InternetShortcut",
                                          wini_key,
                                          wszBuf,
                                          wpath
                                          );
        SAFEFREE(wszBuf);

        if (dres <= 0) {
            ComErrorMsg(croak_on_error, "WritePrivateProfileStringW (_write_ini)", E_FAIL);
            return(S_FALSE);
        }
    }

    return(S_OK);
}

HRESULT
_read_ini_filetime(wpath, wini_key, hash, hash_key_e)
     WCHAR * wpath;
     WCHAR * wini_key;
     HV *   hash;
     hk_e hash_key_e;
{
    WCHAR wszBuf[MY_MAX_PATHW];
    DWORD dres;
    FILETIME filetime;
    FILETIME localtime;
    SYSTEMTIME systime;
    char szTimeBuf[20];
    UINT32 tmpLowBuf[4];
    UINT32 tmpHighBuf[4];
    int ret;

    dres = GetPrivateProfileStringW(
                                    L"InternetShortcut",
                                    wini_key,
                                    0,
                                    wszBuf,
                                    MY_MAX_PATHW,
                                    wpath
                                    );

    if (dres <= 0) {
        HASH_STORE(hash, hash_key_e, newSVsv(&PL_sv_undef));
        return(S_FALSE);
    }

    ret = swscanf(wszBuf, L"%2X%2X%2X%2X%2X%2X%2X%2X",
                  &tmpLowBuf[3],  &tmpLowBuf[2],  &tmpLowBuf[1],  &tmpLowBuf[0],
                  &tmpHighBuf[3], &tmpHighBuf[2], &tmpHighBuf[1], &tmpHighBuf[0]
                  );

    if (ret != 8) {
        return(S_FALSE);
    }


    filetime.dwLowDateTime =
        tmpLowBuf[0] * 256 * 256 * 256 +
        tmpLowBuf[1] * 256 * 256 +
        tmpLowBuf[2] * 256 +
        tmpLowBuf[3];

    filetime.dwHighDateTime =
        tmpHighBuf[0] * 256 * 256 * 256 +
        tmpHighBuf[1] * 256 * 256 +
        tmpHighBuf[2] * 256 +
        tmpHighBuf[3];

    FileTimeToLocalFileTime(&filetime, &localtime);
    FileTimeToSystemTime(&localtime, &systime);

    /* should use CTime or strftime, maybe */
    _stringify_systime(szTimeBuf, systime);

    HASH_STORE(hash, hash_key_e, newSVpv(szTimeBuf, 0));

    return(S_OK);
}

HRESULT
_write_ini_filetime(wpath, wini_key, hash, hash_key_e, croak_on_error)
     WCHAR * wpath;
     WCHAR * wini_key;
     HV *   hash;
     hk_e hash_key_e;
     int croak_on_error;
{
    WCHAR *wszBuf = NULL;
    DWORD dres;
    FILETIME filetime;
    FILETIME localtime;
    SYSTEMTIME systime;
    WCHAR szTimeBuf[17];
    UINT32 tmpLowBuf[4];
    UINT32 tmpHighBuf[4];
    int ret;

    HASH_GET(hash, hash_key_e, wszBuf);
    if (wszBuf != NULL) {

        ret = _wunstringify_systime(wszBuf, systime);
        SAFEFREE(wszBuf);

        if (ret != 6) {
            return(S_FALSE);
        }

        SystemTimeToFileTime(&systime, &localtime);
        LocalFileTimeToFileTime(&localtime, &filetime);
        tmpHighBuf[3] = filetime.dwHighDateTime % 256;
        tmpHighBuf[2] = (filetime.dwHighDateTime / 256) % 256;
        tmpHighBuf[1] = (filetime.dwHighDateTime / 256 / 256) % 256;
        tmpHighBuf[0] = (filetime.dwHighDateTime / 256 / 256 / 256) % 256;
        tmpLowBuf[3]  = filetime.dwLowDateTime % 256;
        tmpLowBuf[2]  = (filetime.dwLowDateTime / 256) % 256;
        tmpLowBuf[1]  = (filetime.dwLowDateTime / 256 / 256) % 256;
        tmpLowBuf[0]  = (filetime.dwLowDateTime / 256 / 256 / 256) % 256;

        swprintf(szTimeBuf, sizeof(szTimeBuf), L"%02X%02X%02X%02X%02X%02X%02X%02X",
                 tmpLowBuf[3],  tmpLowBuf[2],  tmpLowBuf[1],  tmpLowBuf[0],
                 tmpHighBuf[3], tmpHighBuf[2], tmpHighBuf[1], tmpHighBuf[0]
                 );

        dres = WritePrivateProfileStringW(
                                          L"InternetShortcut",
                                          wini_key,
                                          szTimeBuf,
                                          wpath
                                          );

        if (dres <= 0) {
            ComErrorMsg(croak_on_error, "WritePrivateProfileStringW (_write_ini_filetime)", E_FAIL);
            return(S_FALSE);
        }
    }

    return(S_OK);
}

HRESULT
_read_property(pProperty, prop_id, hash, hash_key_e)
     IPropertyStorage ** pProperty;
     PROPID              prop_id;
     HV *                hash;
     hk_e                hash_key_e;
{
    HRESULT hr;
    PROPSPEC    pspec;
    PROPVARIANT pvar;
    FILETIME   localtime;
    SYSTEMTIME systime;
    char szTimeBuf[20];

    PropVariantInit(&pvar);

    pspec.ulKind = PRSPEC_PROPID;
    pspec.propid = prop_id;

    hr = IPropertyStorage_ReadMultiple(*pProperty, 1, &pspec, &pvar);

    if (FAILED(hr)) {
        PropVariantClear(&pvar);
        return(hr);
    }

    if (S_OK != hr) {
        HASH_STORE(hash, hash_key_e, newSVsv(&PL_sv_undef)); /* no valid data */
        PropVariantClear(&pvar);
        return(hr);
    }

    switch (pvar.vt) {
        case VT_LPWSTR :
            HASH_STORE(hash, hash_key_e, SvREFCNT_inc(wstr_to_sv(aTHX_ pvar.pwszVal)));
            break;

        case VT_LPSTR :
            HASH_STORE(hash, hash_key_e, newSVpv(pvar.pszVal, 0));
            break;

        case VT_UI2 :
            HASH_STORE(hash, hash_key_e, newSVuv(pvar.uiVal));
            break;

        case VT_UI4 :
            HASH_STORE(hash, hash_key_e, newSVuv(pvar.ulVal));
            break;

        case VT_I4 :
            HASH_STORE(hash, hash_key_e, newSViv(pvar.lVal));
            break;

        case VT_FILETIME:
            FileTimeToLocalFileTime(&(pvar.filetime),&localtime);
            FileTimeToSystemTime(&localtime,&systime);

            _stringify_systime(szTimeBuf, systime);

            HASH_STORE(hash, hash_key_e, newSVpv(szTimeBuf, 0));
            break;

        case VT_EMPTY :
            HASH_STORE(hash, hash_key_e, newSVsv(&PL_sv_undef));  /* unavailable on your system */
            break;

        default:
            HASH_STORE(hash, hash_key_e, newSVsv(&PL_sv_undef));  /* unavailable on your system */
            break;

    };

    PropVariantClear(&pvar);

    return(S_OK);
}

HRESULT
_write_property(pProperty, prop_id, hash, hash_key_e, vt, croak_on_error)
     IPropertyStorage ** pProperty;
     PROPID              prop_id;
     HV *                hash;
     hk_e                hash_key_e;
     VARTYPE             vt;
     int                 croak_on_error;
{
    HRESULT hr;
    PROPSPEC    pspec;
    PROPVARIANT pvar;
    FILETIME   localtime;
    SYSTEMTIME systime;
    WCHAR *wszBuf = NULL;
    LPSTR szBuf = NULL;
    int nLen;
    int ret;
    FILETIME filetime;
    BOOL storage = TRUE;

    PropVariantInit(&pvar);

    HASH_GET(hash, hash_key_e, wszBuf);
    if (wszBuf != NULL) {
        pspec.ulKind = PRSPEC_PROPID;
        pspec.propid = prop_id;
        pvar.vt = vt;
        switch (pvar.vt) {
            case VT_LPWSTR :
                pvar.pwszVal = wszBuf;
                break;
            case VT_LPSTR :
                nLen = wcslen(wszBuf)+1;
                szBuf = CoTaskMemAlloc(nLen);
                if (szBuf != NULL) {
                    wcstombs(szBuf, wszBuf, nLen);
                    pvar.pszVal = szBuf;
                } else {
                    storage = FALSE;
                }
                break;
            case VT_UI2 :
                pvar.uiVal = (USHORT) _wtoi(wszBuf);
                break;
            case VT_UI4 :
                pvar.ulVal = wcstoul(wszBuf, NULL, 0);
                break;
            case VT_I4 :
                pvar.lVal = wcstol(wszBuf, NULL, 0);
                break;
            case VT_FILETIME:
                ret = _wunstringify_systime(wszBuf, systime);
                if (ret == 8) {
                    SystemTimeToFileTime(&systime, &localtime);
                    LocalFileTimeToFileTime(&localtime, &filetime);
                    pvar.filetime = filetime;
                } else {
                    storage = FALSE;
                }
                break;
            default:
                break;
        }

        if (storage == TRUE) {
            hr = IPropertyStorage_WriteMultiple(*pProperty, 1, &pspec, &pvar, PID_FIRST_USABLE);
        }

        SAFEFREE(wszBuf);

        if (szBuf != NULL) {
	    CoTaskMemFree(szBuf);
            szBuf = NULL;
        }


        if (storage == TRUE) {
            if (FAILED(hr)) {
                ComErrorMsg(croak_on_error, "IPropertyStorage_WriteMultiple (_write_property)", hr);
                return(hr);
            } else {
                hr = IPropertyStorage_Commit(*pProperty, STGC_DEFAULT );
                if (FAILED(hr)) {
                    ComErrorMsg(croak_on_error, "IPropertyStorage_Commit (_write_property)", hr);
                    return(hr);
                }
	    }
        }
    }

    return(S_OK);
}

HRESULT
_read_shortcut_properties(pPropSet, hash, croak_on_error)
     IPropertySetStorage ** pPropSet;
     HV *                   hash;
     int                    croak_on_error;
{
    HRESULT hr;
    IPropertyStorage * pProp = NULL;
    HV * shcut;

    hr = IPropertySetStorage_Open(*pPropSet,
                                  &FMTID_Intshcut,
                                  _STGM_SHARE_READ,
                                  &pProp);

    if (FAILED(hr)) {
        ComErrorMsg(croak_on_error, "IPropertySetStorage_Open (_read_shortcut_properties)", hr);
        return(hr);
    }

    shcut = newHV();

    _read_property(&pProp, PID_IS_URL,         shcut, HK_URL);
    _read_property(&pProp, PID_IS_NAME,        shcut, HK_NAME);
    _read_property(&pProp, PID_IS_WORKINGDIR,  shcut, HK_WORKDIR);
    _read_property(&pProp, PID_IS_HOTKEY,      shcut, HK_HOTKEY);
    _read_property(&pProp, PID_IS_SHOWCMD,     shcut, HK_SHOWCMD);
    _read_property(&pProp, PID_IS_ICONINDEX,   shcut, HK_ICONINDEX);
    _read_property(&pProp, PID_IS_ICONFILE,    shcut, HK_ICONFILE);
    _read_property(&pProp, PID_IS_WHATSNEW,    shcut, HK_WHATSNEW);
    _read_property(&pProp, PID_IS_AUTHOR,      shcut, HK_AUTHOR);
    _read_property(&pProp, PID_IS_DESCRIPTION, shcut, HK_DESC);
    _read_property(&pProp, PID_IS_COMMENT,     shcut, HK_COMMENT);


    HASH_STORE(hash, HK_PROP, newRV_noinc((SV *) shcut));

    IPropertyStorage_Release(pProp);

    return(S_OK);
}

HRESULT
_write_shortcut_properties(pPropSet, hash, croak_on_error)
     IPropertySetStorage ** pPropSet;
     HV *                   hash;
     int                    croak_on_error;
{
    HRESULT hr;
    IPropertyStorage * pProp = NULL;
    SV **sv;
    HV *shcut;

    if (((sv = hv_fetch(hash, "properties", strlen("properties"), 0)) == NULL) ||
        (! SvOK(*sv)) ||
        (! SvROK(*sv)) ||
        (SvTYPE(SvRV(*sv)) != SVt_PVHV)) {
        return(S_FALSE);
    }

    shcut = (HV *) SvRV(*sv);

    hr = IPropertySetStorage_Open(*pPropSet,
                                  &FMTID_Intshcut,
                                  _STGM_SHARE_WRITE,
                                  &pProp
                                  );

    if (FAILED(hr)) {
        ComErrorMsg(croak_on_error, "IPropertySetStorage_Create (_write_shortcut_properties)", hr);
        return(hr);
    }

    _write_property(&pProp, PID_IS_URL,         shcut, HK_URL, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_NAME,        shcut, HK_NAME, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_WORKINGDIR,  shcut, HK_WORKDIR, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_HOTKEY,      shcut, HK_HOTKEY, VT_UI2, croak_on_error);
    _write_property(&pProp, PID_IS_SHOWCMD,     shcut, HK_SHOWCMD, VT_I4, croak_on_error);
    _write_property(&pProp, PID_IS_ICONINDEX,   shcut, HK_ICONINDEX, VT_I4, croak_on_error);
    _write_property(&pProp, PID_IS_ICONFILE,    shcut, HK_ICONFILE, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_WHATSNEW,    shcut, HK_WHATSNEW, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_AUTHOR,      shcut, HK_AUTHOR, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_DESCRIPTION, shcut, HK_DESC, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_IS_COMMENT,     shcut, HK_COMMENT, VT_LPWSTR, croak_on_error);

    IPropertyStorage_Release(pProp);

    return(S_OK);
}

HRESULT
_read_intsite_properties(pPropSet, hash, croak_on_error)
     IPropertySetStorage ** pPropSet;
     HV *                   hash;
     int                    croak_on_error;
{
    HRESULT hr;
    IPropertyStorage * pProp = NULL;
    HV * intsite;

    hr = IPropertySetStorage_Open(*pPropSet,
                                  &FMTID_InternetSite,
                                  _STGM_SHARE_READ,
                                  &pProp
                                  );

    if (FAILED(hr)) {
        ComErrorMsg(croak_on_error, "IPropertySetStorage_Open (_read_intsite_properties)", hr);
        return(hr);
    }

    intsite = newHV();

    _read_property(&pProp, PID_INTSITE_WHATSNEW,    intsite, HK_WHATSNEW);
    _read_property(&pProp, PID_INTSITE_AUTHOR  ,    intsite, HK_AUTHOR);
    _read_property(&pProp, PID_INTSITE_LASTVISIT,   intsite, HK_LASTVISITS);
    _read_property(&pProp, PID_INTSITE_LASTMOD,     intsite, HK_LASTMOD);
    _read_property(&pProp, PID_INTSITE_VISITCOUNT,  intsite, HK_VISITCOUNT);
    _read_property(&pProp, PID_INTSITE_DESCRIPTION, intsite, HK_DESC);
    _read_property(&pProp, PID_INTSITE_COMMENT,     intsite, HK_COMMENT);
    _read_property(&pProp, PID_INTSITE_FLAGS,       intsite, HK_FLAGS);
    _read_property(&pProp, PID_INTSITE_URL,         intsite, HK_URL);
    _read_property(&pProp, PID_INTSITE_TITLE,       intsite, HK_TITLE);
    _read_property(&pProp, PID_INTSITE_CODEPAGE,    intsite, HK_CODEPAGE);
    _read_property(&pProp, PID_INTSITE_ICONINDEX,   intsite, HK_ICONINDEX);
    _read_property(&pProp, PID_INTSITE_ICONFILE,    intsite, HK_ICONFILE);

    HASH_STORE(hash, HK_SITE_PROP, newRV_noinc((SV *) intsite));

    IPropertyStorage_Release(pProp);

    return S_OK;
}

HRESULT
_write_intsite_properties(pPropSet, hash, croak_on_error)
     IPropertySetStorage ** pPropSet;
     HV *                   hash;
     int                    croak_on_error;
{
    HRESULT hr;
    IPropertyStorage * pProp = NULL;
    SV **sv;
    HV *intsite;

    if (((sv = hv_fetch(hash, "site_properties", strlen("site_properties"), 0)) == NULL) ||
        (! SvOK(*sv)) ||
        (! SvROK(*sv)) ||
        (SvTYPE(SvRV(*sv)) != SVt_PVHV)) {
        return(S_FALSE);
    }

    intsite = (HV *) SvRV(*sv);

    hr = IPropertySetStorage_Open(*pPropSet,
                                  &FMTID_InternetSite,
                                  _STGM_SHARE_WRITE,
                                  &pProp
                                  );
    if (FAILED(hr)) {
        ComErrorMsg(croak_on_error, "IPropertySetStorage_Create (_write_intsite_properties)", hr);
        return(hr);
    }

    _write_property(&pProp, PID_INTSITE_WHATSNEW,    intsite, HK_WHATSNEW, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_AUTHOR,      intsite, HK_AUTHOR, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_LASTVISIT,   intsite, HK_LASTVISITS, VT_FILETIME, croak_on_error);
    _write_property(&pProp, PID_INTSITE_LASTMOD,     intsite, HK_LASTMOD, VT_FILETIME, croak_on_error);
    _write_property(&pProp, PID_INTSITE_VISITCOUNT,  intsite, HK_VISITCOUNT, VT_UI4, croak_on_error);
    _write_property(&pProp, PID_INTSITE_DESCRIPTION, intsite, HK_DESC, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_COMMENT,     intsite, HK_COMMENT, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_FLAGS,       intsite, HK_FLAGS, VT_UI4, croak_on_error);
    _write_property(&pProp, PID_INTSITE_URL,         intsite, HK_URL, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_TITLE,       intsite, HK_TITLE, VT_LPWSTR, croak_on_error);
    _write_property(&pProp, PID_INTSITE_CODEPAGE,    intsite, HK_CODEPAGE, VT_UI4, croak_on_error);
    _write_property(&pProp, PID_INTSITE_ICONINDEX,   intsite, HK_ICONINDEX, VT_I4, croak_on_error);
    _write_property(&pProp, PID_INTSITE_ICONFILE,    intsite, HK_ICONFILE, VT_LPWSTR, croak_on_error);

    IPropertyStorage_Release(pProp);

    return S_OK;
}

MODULE = Win32::Unicode::InternetShortcut		PACKAGE = Win32::Unicode::InternetShortcut

PROTOTYPES: DISABLE

long
constant(name)
    char *name
INIT:
  DWORD val = constant(name);
    if ((val <= 0) && (errno == EINVAL || errno == ENOENT)) {
      XSRETURN_UNDEF;
    }
CODE:
    RETVAL = val;
OUTPUT:
    RETVAL

void
_Instance(croak_on_error)
    int croak_on_error
PPCODE:
    HRESULT hres;
    IUniformResourceLocatorW* ilocator;

    hres = CoCreateInstance(&CLSID_InternetShortcut, NULL, CLSCTX_INPROC_SERVER,
			    &IID_IUniformResourceLocatorW, (LPVOID *)&ilocator);

    EXTEND(SP,2);
    if (SUCCEEDED(hres)) {
      IPersistFile* ifile;
      hres = ilocator->lpVtbl->QueryInterface(ilocator, &IID_IPersistFile, (LPVOID *)&ifile);
      if (SUCCEEDED(hres)) {
	ST(0)=sv_2mortal(newSViv((DWORD_PTR) ilocator));
	ST(1)=sv_2mortal(newSViv((DWORD_PTR) ifile));
	XSRETURN(2);
      } else {
	ComErrorMsg(croak_on_error, "IUniformResourceLocatorW_QueryInterface (_Instance)", hres);
	XSRETURN_NO;
      }
    } else {
      ComErrorMsg(croak_on_error, "CoCreateInstance (_Instance)", hres);
    }

    XSRETURN_NO;

void
_Release(ilocator,ifile)
     IUniformResourceLocatorW * ilocator
     IPersistFile * ifile
PPCODE:
     IPersistFile_Release(ifile);
     ilocator->lpVtbl->Release(ilocator);
     XSRETURN_YES;


void
_CoInitializeEx(dwCoInit,croak_on_error)
     DWORD dwCoInit
     int croak_on_error
PPCODE:
    {
      HRESULT hres = CoInitializeEx(NULL, dwCoInit);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error,"CoInitializeEx", hres);
	XSRETURN_NO;
      }
    }

void
_CoInitialize(croak_on_error)
     int croak_on_error
PPCODE:
    {
      HRESULT hres = CoInitialize(NULL);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error,"CoInitialize", hres);
	XSRETURN_NO;
      }
    }

void
_CoUninitialize(...)
PPCODE:
    CoUninitialize();
    XSRETURN_YES;


void
_xssave(self, ilocator, ifile, path, url, croak_on_error)
     SV * self
     IUniformResourceLocatorW * ilocator
     IPersistFile * ifile
     SV * path
     SV * url
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR wabsPath[MY_MAX_PATHW];
      HV * hash = (HV *) SvRV(self);
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      WCHAR *wurl = sv_to_wstr(aTHX_ url);

      if (_wfullpath(wabsPath, wpath, MY_MAX_PATHW) == NULL) {
	ComErrorMsg(croak_on_error,"_wfullpath (_xssave)", E_FAIL);
	SAFEFREE(wpath);
	SAFEFREE(wurl);
	XSRETURN_NO;
      }

      HASH_STORE(hash, HK_PATH, SvREFCNT_inc(wstr_to_sv(aTHX_ wpath)));
      HASH_STORE(hash, HK_FULLPATH, SvREFCNT_inc(wstr_to_sv(aTHX_ wabsPath)));
      HASH_STORE(hash, HK_URL, SvREFCNT_inc(wstr_to_sv(aTHX_ wurl)));

      SAFEFREE(wpath);

      hres = ilocator->lpVtbl->SetURL(ilocator, wurl, 0);
      if (hres != S_OK) {
	ComErrorMsg(croak_on_error,"IUniformResourceLocatorW_SetUrl (_xssave)", hres);
	SAFEFREE(wurl);
	XSRETURN_NO;
      }

      SAFEFREE(wurl);

      _write_ini_filetime(wabsPath, IK_MODIFIED,  hash, HK_MODIFIED, croak_on_error);
      _write_ini(         wabsPath, IK_ICONINDEX, hash, HK_ICONINDEX, croak_on_error);
      _write_ini(         wabsPath, IK_ICONFILE,  hash, HK_ICONFILE, croak_on_error);

      hres = IPersistFile_Save(ifile, wabsPath, TRUE);

      if (SUCCEEDED(hres)) {
	IPersistFile_SaveCompleted(ifile, wabsPath);
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IPersistFile_Save (_xssave)", hres);
	XSRETURN_NO;
      }
}

void
_xsload(self, ilocator, ifile, path, croak_on_error)
     SV * self
     IUniformResourceLocatorW * ilocator
     IPersistFile * ifile
     SV * path
     int croak_on_error
 PPCODE:
    {
      HV * hash = (HV *) SvRV(self);
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      WCHAR wabsPath[MY_MAX_PATHW];
      WCHAR *wurl = NULL;
      HRESULT hres;
      LPMALLOC pMalloc = NULL;

      if (FAILED(_set_curfile_and_load(hash, ifile, wpath, wabsPath, croak_on_error))) {
	SAFEFREE(wpath);
	XSRETURN_NO;
      }

      SAFEFREE(wpath);

      if ((hres = CoGetMalloc(1, &pMalloc)) != S_OK) {
	ComErrorMsg(croak_on_error,"CoGetMalloc (_xsload)", hres);
	XSRETURN_NO;
      }

      hres = ilocator->lpVtbl->GetURL(ilocator, &wurl);
      if (SUCCEEDED(hres)) {
        if (wurl != NULL) {
	  HASH_STORE(hash, HK_URL, SvREFCNT_inc(wstr_to_sv(aTHX_ wurl)));
        }
      } else {
	ComErrorMsg(croak_on_error,"IUniformResourceLocatorW::GetURL (_xsload)", hres);
	XSRETURN_NO;
      }

      IMalloc_Free(pMalloc, wurl);

      _read_ini_filetime(wabsPath, IK_MODIFIED,  hash, HK_MODIFIED);
      _read_ini(         wabsPath, IK_ICONINDEX, hash, HK_ICONINDEX);
      _read_ini(         wabsPath, IK_ICONFILE,  hash, HK_ICONFILE);

      XSRETURN_YES;
    }

void
_xsload_properties(self, ilocator, ifile, path, croak_on_error)
    SV * self;
    IUniformResourceLocatorW * ilocator
    IPersistFile * ifile
    SV * path;
    int croak_on_error
 PPCODE:
    {
      HRESULT hres;
      HV * hash = (HV *) SvRV(self);
      WCHAR wabsPath[MY_MAX_PATHW];
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      IPropertySetStorage * pPropSetStg = NULL;

      if (FAILED(_set_curfile_and_load(hash, ifile, wpath, wabsPath, croak_on_error))) {
	SAFEFREE(wpath);
	XSRETURN_NO;
      }

      SAFEFREE(wpath);

      hres = IPersistFile_QueryInterface(ifile, &IID_IPropertySetStorage, (LPVOID *) &pPropSetStg);

      if (hres != S_OK) {
	ComErrorMsg(croak_on_error, "IPersistFile_QueryInterface (_xsload_properties)", hres);
	XSRETURN_NO;
      }

      _read_shortcut_properties(&pPropSetStg, hash, croak_on_error);
      _read_intsite_properties(&pPropSetStg, hash, croak_on_error);
      IPropertySetStorage_Release(pPropSetStg);

      SAFEFREE(wpath);

      XSRETURN_YES;
    }

void
_xssave_properties(self, ilocator, ifile, path, croak_on_error)
    SV * self;
    IUniformResourceLocatorW * ilocator
    IPersistFile * ifile
    SV * path;
    int croak_on_error
 PPCODE:
    {
      HRESULT hres;
      HV * hash = (HV *) SvRV(self);
      WCHAR wabsPath[MY_MAX_PATHW];
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      IPropertySetStorage * pPropSetStg = NULL;

      if (FAILED(_set_curfile_and_load(hash, ifile, wpath, wabsPath, croak_on_error))) {
	SAFEFREE(wpath);
	XSRETURN_NO;
      }

      SAFEFREE(wpath);

      hres = IPersistFile_QueryInterface(ifile, &IID_IPropertySetStorage, (LPVOID *) &pPropSetStg);

      if (hres != S_OK) {
	ComErrorMsg(croak_on_error, "IPersistFile_QueryInterface (_xssave_properties)", hres);
	XSRETURN_NO;
      }

      _write_shortcut_properties(&pPropSetStg, hash, croak_on_error);
      _write_intsite_properties(&pPropSetStg, hash, croak_on_error);
      IPropertySetStorage_Release(pPropSetStg);

      hres = IPersistFile_Save(ifile, wpath, TRUE);
      SAFEFREE(wpath);
      if (hres != S_OK) {
	ComErrorMsg(croak_on_error, "IPersistFile_Save (_xssave_properties)", hres);
	XSRETURN_NO;
      }

      XSRETURN_YES;
    }

void
_xsinvoke_url(self, ilocator, ifile, url, croak_on_error)
    SV * self;
    IUniformResourceLocatorW * ilocator
    IPersistFile * ifile
    SV * url;
    int croak_on_error
 PPCODE:
    {
      HRESULT hres;
      HV * hash = (HV *) SvRV(self);
      URLINVOKECOMMANDINFOW pCmd;
      WCHAR *wurl = sv_to_wstr(aTHX_ url);

      pCmd.dwcbSize   = sizeof(URLINVOKECOMMANDINFO);
      pCmd.dwFlags    = IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB;
      pCmd.hwndParent = NULL;
      pCmd.pcszVerb   = NULL;

      hres = ilocator->lpVtbl->SetURL(ilocator, wurl, 0);
      if (hres != S_OK) {
	ComErrorMsg(croak_on_error, "IUniformResourceLocatorW_SetUrl (_xsinvoke_url)", hres);
	SAFEFREE(wurl);
	XSRETURN_NO;
      }

      SAFEFREE(wurl);

      hres = ilocator->lpVtbl->InvokeCommand(ilocator, &pCmd);

      if (SUCCEEDED(hres)) {
	ComErrorMsg(croak_on_error, "IPersistFile_Save (_xsinvoke_url)", hres);
	XSRETURN_NO;
      } else {
	XSRETURN_YES;
      }
    }

void
_xsinvoke(self, ilocator, ifile, path, croak_on_error)
     SV * self;
     IUniformResourceLocatorW * ilocator
     IPersistFile * ifile
     SV * path;
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      HV * hash = (HV *) SvRV(self);
      WCHAR wabsPath[MY_MAX_PATHW];
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      URLINVOKECOMMANDINFOW pCmd;

      if (FAILED(_set_curfile_and_load(hash, ifile, wpath, wabsPath, croak_on_error))) {
	SAFEFREE(wpath);
	XSRETURN_NO;
      }

      SAFEFREE(wpath);

      pCmd.dwcbSize   = sizeof(URLINVOKECOMMANDINFO);
      pCmd.dwFlags    = IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB;
      pCmd.hwndParent = NULL;
      pCmd.pcszVerb   = NULL;

      hres = ilocator->lpVtbl->InvokeCommand(ilocator, &pCmd);

      if (SUCCEEDED(hres)) {
	ComErrorMsg(croak_on_error, "IPersistFile_Save (_xsinvoke)", hres);
	XSRETURN_NO;
      } else {
	XSRETURN_YES;
      }
    }
