/*

  Win32::InternetShortcut

  ver 0.04

  Copyright (C) 2006 by Kenichi Ishigaki <ishigaki@cpan.org>

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

*/

/*
  TECH NOTES:

  See MSDN for details.

    http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/programmersguide/shell_int/shell_int_programming/shortcuts/internet_shortcuts.asp

  However, do NOT trust it too much. Some of the features might not be
  implemented or changed for your PC.

  Below sites provide some useful information (at least for me).

  - http://www.cyanwerks.com/file-format-url.html
  - http://www.techieone.com/detail-6264254.html
  - http://www.arstdesign.com/articles/iefavorites.html
*/

#include <shlobj.h>
#include <intshcut.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "InternetShortcut.h"

HRESULT _initialize(
  IUniformResourceLocator ** pURL,
  IPersistFile **            pPFile
)
{
  HRESULT hr;

  hr = CoCreateInstance(
    CLSID_InternetShortcut,
    NULL,
    CLSCTX_INPROC_SERVER,
    IID_IUniformResourceLocator,
    (LPVOID *) pURL
  );
  if ( FAILED( hr ) )
    return hr;

  hr = (*pURL)->QueryInterface(IID_IPersistFile, (LPVOID *) pPFile);
  if ( FAILED( hr ) )
    return hr;

  return S_OK;
}

void _release(
  IUniformResourceLocator ** pURL,
  IPersistFile **            pPFile
)
{
  if (pPFile != NULL)
    (*pPFile)->Release();

  if (pURL != NULL)
    (*pURL)->Release();

  CoUninitialize();
}

HRESULT _read_ini(
  char * path,
  char * ini_key,
  HV *   hash,
  char * hash_key
)
{
  char szBuf[MAX_PATH];

  GetPrivateProfileString(
    "InternetShortcut",
    ini_key,
    "",
    szBuf,
    sizeof(szBuf),
    path
  );
  hash_store(hash, hash_key, newSVpv(szBuf, 0));

  return S_OK;
}

HRESULT _read_ini_filetime(
  char * path,
  char * ini_key,
  HV *   hash,
  char * hash_key
)
{
  char szBuf[MAX_PATH];

  GetPrivateProfileString(
    "InternetShortcut",
    ini_key,
    "",
    szBuf,
    sizeof(szBuf),
    path
  );

  FILETIME filetime;
  FILETIME localtime;
  SYSTEMTIME systime;
  char szTimeBuf[20];

  DWORD tmpLowBuf[3];
  DWORD tmpHighBuf[3];

  int ret;
  ret = sscanf(szBuf, "%2X%2X%2X%2X%2X%2X%2X%2X",
    &tmpLowBuf[3],  &tmpLowBuf[2],  &tmpLowBuf[1],  &tmpLowBuf[0],
    &tmpHighBuf[3], &tmpHighBuf[2], &tmpHighBuf[1], &tmpHighBuf[0]
  );

  if (ret != 8)
    return S_FALSE;

  /* XXX: such a dumb thing; there must be a better way */
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

  FileTimeToLocalFileTime(&filetime,&localtime);
  FileTimeToSystemTime(&localtime,&systime);

  /* should use CTime or strftime, maybe */
  _stringify_systime(szTimeBuf, systime);

  hash_store(hash, hash_key, newSVpv(szTimeBuf, 0));

  return S_OK;
}

HRESULT _read_property(
  IPropertyStorage ** pProperty,
  PROPID              prop_id,
  HV *                hash,
  char *              key
)
{
  HRESULT hr;

  PROPSPEC    pspec;
  PROPVARIANT pvar;

  PropVariantInit( &pvar );

  pspec.ulKind = PRSPEC_PROPID;
  pspec.propid = prop_id;

  hr = (*pProperty)->ReadMultiple(1, &pspec, &pvar);

  if ( FAILED( hr ) )
    return hr;

  if ( S_FALSE == hr ) {
    hash_store(hash, key, newSV(0)); /* no valid data */
    return hr;
  }

  switch (pvar.vt)
  {
    case VT_LPWSTR :
      char szBuf[MAX_PATH];

      /* what to do with Unicode? */
      WideCharToMultiByte(
        CP_ACP, 0, pvar.pwszVal, -1, szBuf, sizeof(szBuf), NULL, NULL
      );

      hash_store(hash, key, newSVpv(szBuf, 0));
      break;

    case VT_UI2 :
      hash_store(hash, key, newSVuv(pvar.uiVal));
      break;

    case VT_UI4 :
      hash_store(hash, key, newSVuv(pvar.ulVal));
      break;

    case VT_I4 :
      hash_store(hash, key, newSViv(pvar.lVal));
      break;

    case VT_FILETIME :
      FILETIME   localtime;
      SYSTEMTIME systime;
      char szTimeBuf[20];

      FileTimeToLocalFileTime(&(pvar.filetime),&localtime);
      FileTimeToSystemTime(&localtime,&systime);

      /* should use CTime or strftime, maybe */
      _stringify_systime(szTimeBuf, systime);

      hash_store(hash, key, newSVpv(szTimeBuf, 0));
      break;

    case VT_EMPTY :
      hash_store(hash, key, newSV(0));  /* unavailable on your system */
      break;

    default:
/*    printf("oops! MSDN didn't say so! : %s (%d)\n\n", key, pvar.vt); */
      break;

  };

  PropVariantClear( &pvar );

  return S_OK;
}

HRESULT _store_shortcut_properties(
  IPropertySetStorage ** pPropSet,
  HV *                   hash
)
{
  HRESULT hr;
  IPropertyStorage * pProp = NULL;

  hr = (*pPropSet)->Open(
    FMTID_Intshcut, _STGM_SHARE_READ, &pProp
  );

  if ( FAILED( hr ) )
    return hr;

  HV * shcut = newHV();

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

  hash_store(hash, HK_PROP, newRV_noinc((SV *) shcut));

  pProp->Release();

  return S_OK;
}

HRESULT _store_intsite_properties(
  IPropertySetStorage ** pPropSet,
  HV *                   hash
)
{
  HRESULT hr;
  IPropertyStorage * pProp = NULL;

  hr = (*pPropSet)->Open(
    FMTID_InternetSite, _STGM_SHARE_READ, &pProp
  );

  if ( FAILED( hr ) )
    return hr;

  HV * intsite = newHV();

  _read_property(&pProp, PID_INTSITE_WHATSNEW,    intsite, HK_WHATSNEW);
  _read_property(&pProp, PID_INTSITE_LASTVISIT,   intsite, HK_LASTVISITS);
  _read_property(&pProp, PID_INTSITE_LASTMOD,     intsite, HK_LASTMOD);
  _read_property(&pProp, PID_INTSITE_VISITCOUNT,  intsite, HK_VISITCOUNT);
  _read_property(&pProp, PID_INTSITE_DESCRIPTION, intsite, HK_DESC);
  _read_property(&pProp, PID_INTSITE_COMMENT,     intsite, HK_COMMENT);
  _read_property(&pProp, PID_INTSITE_FLAGS,       intsite, HK_FLAGS);
  _read_property(&pProp, PID_INTSITE_URL,         intsite, HK_URL);
  _read_property(&pProp, PID_INTSITE_TITLE,       intsite, HK_TITLE);
  _read_property(&pProp, PID_INTSITE_CODEPAGE,    intsite, HK_CODEPAGE);

  hash_store(hash, HK_SITE_PROP, newRV_noinc((SV *) intsite));

  pProp->Release();

  return S_OK;
}

MODULE = Win32::InternetShortcut PACKAGE = Win32::InternetShortcut PREFIX = xs_

PROTOTYPES: DISABLE

int
xs_save(self, path, url)
    SV * self;
    SV * path;
    SV * url;

  PREINIT:
    HRESULT hr;
    IUniformResourceLocator * pURL   = NULL;
    IPersistFile *            pPFile = NULL;

  CODE:
    HV * hash;
    hash = (HV *) SvRV(self);

    /* should be another subroutine */
    /* what to do with Unicode? */
    char  szPath[MAX_PATH];
    WCHAR wszPath[MAX_PATH];
    {
      _fullpath(szPath, SvPV_nolen(path), sizeof(szPath));
      MultiByteToWideChar(CP_ACP, 0, szPath, -1, wszPath, sizeof(wszPath));
      hash_store(hash, HK_PATH,     newSVsv(path));
      hash_store(hash, HK_FULLPATH, newSVpv(szPath, 0));
    }

    if ( FAILED( CoInitialize(NULL) ) )
      XSRETURN_UNDEF;

    hr = _initialize(&pURL, &pPFile);
    if ( SUCCEEDED(hr) ) {
      hash_store(hash, HK_URL, newSVsv(url));

      pURL->SetURL(SvPV_nolen(url), 0);

      pPFile->Save(wszPath, TRUE);
    }

    _release(&pURL, &pPFile);

    XSRETURN_YES;

  OUTPUT:
    RETVAL

int
xs_load(self, path)
    SV * self;
    SV * path;

  PREINIT:

  CODE:
    HV * hash;
    hash = (HV *) SvRV(self);

    /* should be another subroutine */
    /* what to do with Unicode? */
    char  szPath[MAX_PATH];
    {
      _fullpath(szPath, SvPV_nolen(path), sizeof(szPath));
      hash_store(hash, HK_PATH,     newSVsv(path));
      hash_store(hash, HK_FULLPATH, newSVpv(szPath, 0));
    }

    _read_ini(         szPath, IK_URL,       hash, HK_URL);
    _read_ini_filetime(szPath, IK_MODIFIED,  hash, HK_MODIFIED);
    _read_ini(         szPath, IK_ICONINDEX, hash, HK_ICONINDEX);
    _read_ini(         szPath, IK_ICONFILE,  hash, HK_ICONFILE);

    XSRETURN_YES;

  OUTPUT:
    RETVAL

int
xs_load_properties(self, path)
    SV * self;
    SV * path;

  PREINIT:
    HRESULT hr;
    IUniformResourceLocator * pURL   = NULL;
    IPersistFile *            pPFile = NULL;

  CODE:
    HV * hash;
    hash = (HV *) SvRV(self);

    /* should be another subroutine */
    /* what to do with Unicode? */
    char  szPath[MAX_PATH];
    WCHAR wszPath[MAX_PATH];
    {
      _fullpath(szPath, SvPV_nolen(path), sizeof(szPath));
      MultiByteToWideChar(CP_ACP, 0, szPath, -1, wszPath, sizeof(wszPath));
      hash_store(hash, HK_PATH,     newSVsv(path));
      hash_store(hash, HK_FULLPATH, newSVpv(szPath, 0));
    }

    if ( FAILED( CoInitialize(NULL) ) )
      XSRETURN_UNDEF;

    hr = _initialize(&pURL, &pPFile);
    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    hr = pPFile->Load(wszPath, _STGM_SHARE_READ);

    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    IPropertySetStorage * pPropSetStg = NULL;

    hr = pPFile->QueryInterface(
      IID_IPropertySetStorage, (LPVOID *) &pPropSetStg
    );

    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    hr = _store_shortcut_properties(&pPropSetStg, hash);
    hr = _store_intsite_properties(&pPropSetStg, hash);

    pPropSetStg->Release();

    _release(&pURL, &pPFile);

    XSRETURN_YES;

  OUTPUT:
    RETVAL

int
xs_invoke_url(self, url)
    SV * self;
    SV * url;

  PREINIT:
    HRESULT hr;
    IUniformResourceLocator * pURL   = NULL;
    IPersistFile *            pPFile = NULL;

  CODE:
    HV * hash;
    hash = (HV *) SvRV(self);

    if ( FAILED( CoInitialize(NULL) ) )
      XSRETURN_UNDEF;

    hr = _initialize(&pURL, &pPFile);
    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    URLINVOKECOMMANDINFO pCmd;

    pCmd.dwcbSize   = sizeof(URLINVOKECOMMANDINFO);
    pCmd.dwFlags    = IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB;
    pCmd.hwndParent = NULL;
    pCmd.pcszVerb   = NULL;

    pURL->SetURL(SvPV_nolen(url), 0);

    pURL->InvokeCommand(&pCmd);

    _release(&pURL, &pPFile);

    XSRETURN_YES;

  OUTPUT:
    RETVAL

int
xs_invoke(self, path)
    SV * self;
    SV * path;

  PREINIT:
    HRESULT hr;
    IUniformResourceLocator * pURL   = NULL;
    IPersistFile *            pPFile = NULL;

  CODE:
    HV * hash;
    hash = (HV *) SvRV(self);

    /* should be another subroutine */
    /* what to do with Unicode? */
    char  szPath[MAX_PATH];
    WCHAR wszPath[MAX_PATH];
    {
      _fullpath(szPath, SvPV_nolen(path), sizeof(szPath));
      MultiByteToWideChar(CP_ACP, 0, szPath, -1, wszPath, sizeof(wszPath));
      hash_store(hash, HK_PATH,     newSVsv(path));
      hash_store(hash, HK_FULLPATH, newSVpv(szPath, 0));
    }

    if ( FAILED( CoInitialize(NULL) ) )
      XSRETURN_UNDEF;

    hr = _initialize(&pURL, &pPFile);
    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    hr = pPFile->Load(wszPath, _STGM_SHARE_READ);

    if ( FAILED( hr ) ) {
      _release(&pURL, &pPFile);
      XSRETURN_UNDEF;
    }

    URLINVOKECOMMANDINFO pCmd;

    pCmd.dwcbSize   = sizeof(URLINVOKECOMMANDINFO);
    pCmd.dwFlags    = IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB;
    pCmd.hwndParent = NULL;
    pCmd.pcszVerb   = NULL;

    pURL->InvokeCommand(&pCmd);

    _release(&pURL, &pPFile);

    XSRETURN_YES;

  OUTPUT:
    RETVAL
