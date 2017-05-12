#ifndef __WSTRING_CPP
#define __WSTRING_CPP


#include "wstring.h"
#include "misc.h"


///////////////////////////////////////////////////////////////////////////////
//
// copies a single byte string to a unicode string
//
// param:  str  - buffer for single byte string
//         wStr - unicode string
//
// return: success - not null
//         failure - null
//
///////////////////////////////////////////////////////////////////////////////

int MBTWC(PSTR str, PWSTR wStr, int size)
{
  if(!wStr)
    return 0;

  *wStr = '\0';

  return MultiByteToWideChar(CP_ACP, 0, str, -1, wStr, size);
}


///////////////////////////////////////////////////////////////////////////////
//
// copies a unicode string to a single byte string
//
// param:  wStr - unicode string
//         str  - buffer for single byte string
//
// return: success - not null
//         failure - null
//
///////////////////////////////////////////////////////////////////////////////

int WCTMB(PWSTR wStr, PSTR str, int size)
{
  if(!str)
    return 0;

  *str = '\0';

  return WideCharToMultiByte(CP_ACP, NULL, wStr, -1, str, size, NULL, NULL);
}


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory for a unicode string and copies a single byte string to a
// unicode string
//
// param:  str    - single byte string
//         strLen - length of str or -1 if str is null terminated
//
// return: success - unicode string (must be deallocated with FreeStr)
//         failure - null
//
///////////////////////////////////////////////////////////////////////////////

PWSTR S2W(PSTR str, int strLen)
{
  if(!str)
    return NULL;

  PWSTR wStr = NULL;
  int len = strLen == -1 ? strlen(str) + 1 : strLen;

  MBTWC(str, wStr = (PWSTR)NewMem(sizeof(WCHAR) * len), len);

  return wStr;
}


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory for a single byte string and copies a unicode string to a
// single byte string
//
// param:  wStr   - unicode string
//         strLen - length of wStr or -1 if wStr is null terminated
//
// return: success - single byte string (must be deallocated with FreeStr)
//         failure - null
//
///////////////////////////////////////////////////////////////////////////////

PSTR W2S(PWSTR wStr, int strLen)
{
  if(!wStr)
    return NULL;

  PSTR str = NULL;
  int len = strLen == -1 ? wcslen(wStr) + 1 : strLen;

  WCTMB(wStr, str = (PSTR)NewMem(len), len);

  return str;
}


///////////////////////////////////////////////////////////////////////////////
//
// frees a single byte string
//
// param:  str - single byte string
//
// return: nothing
//
///////////////////////////////////////////////////////////////////////////////

void FreeStr(PSTR str)
{
  if(str)
    FreeMem(str);
}


///////////////////////////////////////////////////////////////////////////////
//
// frees a unicode string
//
// param:  wStr - unicode string
//
// return: nothing
//
///////////////////////////////////////////////////////////////////////////////

void FreeStr(PWSTR wStr)
{
  if(wStr)
    FreeMem(wStr);
}


#endif
