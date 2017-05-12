#define WIN32_LEAN_AND_MEAN

#ifndef __PLMISC_CPP
#define __PLMISC_CPP
#endif


#include <windows.h>

#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// index to access tls space
DWORD TlsIndex = -1;


///////////////////////////////////////////////////////////////////////////////
//
// functions
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// get/put strings, pointers and int's from/to hashes, arrays and scalars
// safely
//
///////////////////////////////////////////////////////////////////////////////

PWSTR WStrFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item)
    return S2W(SvPV(*item, PL_na));
  else
    return NULL;
}


PSTR StrFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item)
    return SvPV(*item, PL_na);
  else
    return NULL;
}


int SLenFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item)
    return SvLEN(*item) - 1;
  else
    return NULL;
}


PVOID PtrFromHash(PERL_CALL HV *hash, PSTR idx, unsigned *len, BOOL isRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item)
    return len ? SvPV(*item, *len) : SvPV(*item, PL_na);
  else
    return NULL;
}


int IntFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item)
    return SvIV(*item);
  else
    return NULL;
}


HV *HashFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef, BOOL convRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item) {
    SV *itemDeRef = convRef && SvTYPE(*item) == SVt_RV ? SvRV(*item) : *item;

    return SvTYPE(itemDeRef) == SVt_PVHV ? (HV*)itemDeRef : NULL;
  }
  else
    return NULL;
}


AV *ArrayFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef, BOOL convRef)
{
  if (isRef && hash) {
    if (!(hash = SvROK(hash) ? (HV*)SvRV(hash) : NULL))
      return NULL;

    if (SvTYPE(hash) != SVt_PVHV)
      return NULL;
  }

  SV **item = hash ? hv_fetch(hash, idx, strlen(idx), 0) : NULL;

  if (item && *item) {
    SV *itemDeRef = convRef && SvTYPE(*item) == SVt_RV ? SvRV(*item) : *item;

    return SvTYPE(itemDeRef) == SVt_PVAV ? (AV*)itemDeRef : NULL;
  }
  else
    return NULL;
}


PWSTR WStrFromArray(PERL_CALL AV *array, int idx, BOOL isRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item)
    return S2W(SvPV(*item, PL_na));
  else
    return NULL;
}


PSTR StrFromArray(PERL_CALL AV *array, int idx, BOOL isRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item)
    return SvPV(*item, PL_na);
  else
    return NULL;
}


int SLenFromArray(PERL_CALL AV *array, int idx, BOOL isRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item)
    return SvLEN(*item) - 1;
  else
    return NULL;
}


PVOID PtrFromArray(PERL_CALL AV *array, int idx, unsigned *len, BOOL isRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item)
    return len ? SvPV(*item, *len) : SvPV(*item, PL_na);
  else
    return NULL;
}


int IntFromArray(PERL_CALL AV *array, int idx, BOOL isRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item)
    return SvIV(*item);
  else
    return NULL;
}


HV *HashFromArray(PERL_CALL AV *array, int idx, BOOL isRef, BOOL convRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item) {
    SV *itemDeRef = convRef && SvTYPE(*item) == SVt_RV ? SvRV(*item) : *item;

    return SvTYPE(itemDeRef) == SVt_PVHV ? (HV*)itemDeRef : NULL;
  }
  else
    return NULL;
}


AV *ArrayFromArray(PERL_CALL AV *array, int idx, BOOL isRef, BOOL convRef)
{
  if (isRef && array) {
    if (!(array = SvROK(array) ? (AV*)SvRV(array) : NULL))
      return NULL;

    if (SvTYPE(array) != SVt_PVAV)
      return NULL;
  }

  SV **item = array ? av_fetch(array, idx, 0) : NULL;

  if (item && *item) {
    SV *itemDeRef = convRef && SvTYPE(*item) == SVt_RV ? SvRV(*item) : *item;

    return SvTYPE(itemDeRef) == SVt_PVAV ? (AV*)itemDeRef : NULL;
  }
  else
    return NULL;
}


PWSTR WStrFromScalar(PERL_CALL SV *string, BOOL isRef)
{
  if (!string)
    return NULL;

  if (isRef && !(string = SvROK(string) ? SvRV(string) : NULL))
    return NULL;

  return S2W(SvPV(string, PL_na));
}


PSTR StrFromScalar(PERL_CALL SV *string, BOOL isRef)
{
  if (!string)
    return NULL;

  if (isRef && !(string = SvROK(string) ? SvRV(string) : NULL))
    return NULL;

  return SvPV(string, PL_na);
}


int SLenFromScalar(PERL_CALL SV *string, BOOL isRef)
{
  if (!string)
    return NULL;

  if (isRef && !(string = SvROK(string) ? SvRV(string) : NULL))
    return NULL;

  return SvLEN(string) - 1;
}


int IntFromScalar(PERL_CALL SV *string, BOOL isRef)
{
  if (!string)
    return NULL;

  if (isRef && !(string = SvROK(string) ? SvRV(string) : NULL))
    return NULL;

  return SvIV(string);
}


int WStrToHash(PERL_CALL HV *hash, PSTR idx, PWSTR str)
{
  if (!hash || !idx)
    return 0;

  PSTR strPtr = str ? W2S(str) : NULL;

  if (strPtr)
    hv_store(hash, idx, strlen(idx), newSVpv(strPtr, strlen(strPtr)), 0);

  FreeStr(strPtr);

  return 1;
}


int WNStrToHash(PERL_CALL HV *hash, PSTR idx, PWSTR str, DWORD strLen)
{
  if (!hash || !idx)
    return 0;

  PSTR strPtr = str ? W2S(str, strLen) : NULL;

  if (strPtr) {
    strPtr[strLen - 1] = 0;
    hv_store(hash, idx, strlen(idx), newSVpv(strPtr, strlen(strPtr)), 0);
  }

  FreeStr(strPtr);

  return 1;
}


int StrToHash(PERL_CALL HV *hash, PSTR idx, PSTR str)
{
  if (!hash || !idx)
    return 0;

  if (str)
    hv_store(hash, idx, strlen(idx), newSVpv(str, strlen(str)), 0);

  return 1;
}


int PtrToHash(PERL_CALL HV *hash, PSTR idx, PVOID ptr, int len)
{
  if (!hash || !idx)
    return 0;

  if (ptr)
    hv_store(hash, idx, strlen(idx), newSVpv((PSTR)ptr, len), 0);

  return 1;
}


int IntToHash(PERL_CALL HV *hash, PSTR idx, int val)
{
  if (!hash || !idx)
    return 0;

  hv_store(hash, idx, strlen(idx), newSViv(val), 0);

  return 1;
}


int RefToHash(PERL_CALL HV *hash, PSTR idx, PVOID ptr)
{
  if (!hash || !idx)
    return 0;

  if (ptr)
    hv_store(hash, idx, strlen(idx), (SV*)newRV((SV*)ptr), 0);

  return 1;
}


int WStrToArray(PERL_CALL AV *array, PWSTR str)
{
  if (!array)
    return 0;

  PSTR strPtr = str ? W2S(str) : NULL;

  if (strPtr)
    av_push(array, newSVpv(strPtr, strlen(strPtr)));

  FreeStr(strPtr);

  return 1;
}


int WNStrToArray(PERL_CALL AV *array, PWSTR str, DWORD strLen)
{
  if (!array)
    return 0;

  PSTR strPtr = str ? W2S(str, strLen) : NULL;

  if (strPtr) {
    strPtr[strLen - 1] = 0;
    av_push(array, newSVpv(strPtr, strlen(strPtr)));
  }

  FreeStr(strPtr);

  return 1;
}


int StrToArray(PERL_CALL AV *array, PSTR str)
{
  if (!array)
    return 0;

  if (str)
    av_push(array, newSVpv(str, strlen(str)));

  return 1;
}


int IntToArray(PERL_CALL AV *array, int val)
{
  if (!array)
    return 0;

  av_push(array, newSViv(val));

  return 1;
}


int PtrToArray(PERL_CALL AV *array, PVOID ptr, int len)
{
  if (!array)
    return 0;

  if (ptr)
    av_push(array, newSVpv((PSTR)ptr, len));

  return 1;
}


int RefToArray(PERL_CALL AV *array, PVOID ptr)
{
  if (!array)
    return 0;

  if (ptr)
    av_push(array, (SV*)newRV((SV*)ptr));

  return 1;
}


int WStrToScalar(PERL_CALL SV *string, PWSTR str)
{
  if (!string)
    return 0;

  PSTR strPtr = str ? W2S(str) : NULL;

  if (strPtr)
    sv_setpv(string, strPtr);

  FreeStr(strPtr);

  return 1;
}


int StrToScalar(PERL_CALL SV *string, PSTR str)
{
  if (!string)
    return 0;

  if (str)
    sv_setpv(string, str);

  return 1;
}


int IntToScalar(PERL_CALL SV *string, int val)
{
  if (!string)
    return 0;

  sv_setiv(string, val);

  return 1;
}


int PtrToScalar(PERL_CALL SV *string, PVOID ptr, int len)
{
  if (!string)
    return 0;

  if (ptr)
    sv_setpvn(string, (PSTR)ptr, len);

  return 1;
}

///////////////////////////////////////////////////////////////////////////////
//
// create new hashes, arrays or references; if there is not enougth memory an
// execption will be raised; use the NewHV/AV/RV macros to call it
//
///////////////////////////////////////////////////////////////////////////////

HV *NewHash(PERL_CALL_SINGLE)
{
  HV *hash = newHV();

  if (!hash)
    RaiseException(STATUS_NO_MEMORY, 0, 0, NULL);

  return hash;
}

AV *NewArray(PERL_CALL_SINGLE)
{
  AV *array = newAV();

  if (!array)
    RaiseException(STATUS_NO_MEMORY, 0, 0, NULL);

  return array;
}

SV *NewReference(PERL_CALL SV *refObj)
{
  SV *reference = NULL;

  if (!refObj || !(reference = newRV(refObj)))
    RaiseException(STATUS_NO_MEMORY, 0, 0, NULL);

  return reference;
}

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error variable for the current thread
//
// param:  error	- error value to set
//
// return: last error variable of the current thread
//
///////////////////////////////////////////////////////////////////////////////

DWORD LastError(DWORD error)
{
  TlsSetValue(TlsIndex, (PVOID)error);

  return error;
}


///////////////////////////////////////////////////////////////////////////////
//
// returns the last error variable for the current thread
//
// param:
//
// return: last error variable of the current thread
//
///////////////////////////////////////////////////////////////////////////////

DWORD LastError()
{
  return (DWORD)TlsGetValue(TlsIndex);
}
