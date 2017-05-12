#ifndef __MISC_CPP
#define __MISC_CPP
#endif

#include <windows.h>

#include "misc.h"


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory and initializes the memory with null
//
// param:	 size - size to allocate in bytes
//
// return: ptr to the allocated memory
//
// note:	 if there is not enougth memory, a STATUS_NO_MEMORY exception will be
//				 raised
//
///////////////////////////////////////////////////////////////////////////////

PSTR NewMem(DWORD size)
{
  return
    (PSTR)HeapAlloc(GetProcessHeap(),
                    HEAP_GENERATE_EXCEPTIONS | HEAP_ZERO_MEMORY, size);
}


///////////////////////////////////////////////////////////////////////////////
//
// reallocates memory
//
// param:	 oldPtr - pointer to the current memory
//				 size		- new size in bytes
//				 reinit - if true, rezero the memory
//
// return: ptr to the allocated memory
//
// note:	 if there is not enougth memory, a STATUS_NO_MEMORY exception will be
//				 raised
//
///////////////////////////////////////////////////////////////////////////////

PSTR NewMem(PVOID oldPtr, DWORD size, int reinit)
{
  HANDLE hHeap = GetProcessHeap();

  if (oldPtr) {
    if (HeapSize(hHeap, 0, oldPtr) >= size) {
      if (reinit)
        ZeroMemory(oldPtr, size);

      return (PSTR)oldPtr;
    }

    if (reinit) {
      PVOID newPtr =
        HeapReAlloc(hHeap, HEAP_GENERATE_EXCEPTIONS | HEAP_ZERO_MEMORY,
                    oldPtr, size);

      ZeroMemory(newPtr, size);

      return (PSTR)newPtr;
    }

    return
      (PSTR)HeapReAlloc(hHeap, HEAP_GENERATE_EXCEPTIONS | HEAP_ZERO_MEMORY,
                        oldPtr, size);
  }

  return (PSTR)HeapAlloc(hHeap, HEAP_GENERATE_EXCEPTIONS | HEAP_ZERO_MEMORY,
                         size);
}


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory for a string and copies the contents of str to the
// allocated string
//
// param:	 str - pointer to string to copy
//
// return: ptr to the allocated memory
//
// note:	 if there is not enougth memory, a STATUS_NO_MEMORY exception will be
//				 raised
//
///////////////////////////////////////////////////////////////////////////////

PSTR NewStr(PSTR str)
{
  PSTR newStr = NewMem((str ? lstrlen(str) : 0) + 1);

  if (str)
    lstrcpy(newStr, str);

  return newStr;
}


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory for a unicode string and copies the contents of str to the
// allocated string
//
// param:	 str - pointer to string to copy
//
// return: ptr to the allocated memory
//
// note:	 if there is not enougth memory, a STATUS_NO_MEMORY exception will be
//				 raised
//
///////////////////////////////////////////////////////////////////////////////

PWSTR NewStr(PWSTR str)
{
  PWSTR newStr = (PWSTR)NewMem(((str ? wcslen(str) : 0) + 1) * sizeof(WCHAR));

  if (str)
    wcscpy(newStr, str);

  return newStr;
}


///////////////////////////////////////////////////////////////////////////////
//
// allocates memory for a unicode string and copies the contents of str to the
// allocated string
//
// param:	 str - pointer to string to copy
//
// return: ptr to the allocated memory
//
// note:	 if there is not enougth memory, a STATUS_NO_MEMORY exception will be
//				 raised
//
///////////////////////////////////////////////////////////////////////////////

PWSTR NewStrAsWide(PSTR str)
{
  int newStrSize = ((str ? lstrlen(str) : 0) + 1) * sizeof(WCHAR);
  PWSTR newStr = (PWSTR)NewMem(newStrSize);

  if (str)
    MultiByteToWideChar(CP_ACP, 0, str, -1, newStr, newStrSize);

  return newStr;
}


///////////////////////////////////////////////////////////////////////////////
//
// frees memory
//
// param:	 ptr - pointer to the memory
//
// return: 1 - success
//				 0 - failure
//
///////////////////////////////////////////////////////////////////////////////

int FreeMem(PVOID ptr)
{
  return HeapFree(GetProcessHeap(), 0, ptr) ? 0 : 1;
}


///////////////////////////////////////////////////////////////////////////////
//
// frees memory from an array
//
// param:	 ptr  - pointer to the array
//				 size - number of array items
//
// return: 1 - success
//				 0 - failure
//
///////////////////////////////////////////////////////////////////////////////

int FreeArray(PVOID *ptr, DWORD size)
{
  for(DWORD count = 0; ptr && count < size; count++)
    if (ptr[count])
      FreeMem(ptr[count]), ptr[count] = NULL;

  return 1;
}


///////////////////////////////////////////////////////////////////////////////
//
// copies exception code
//
// param:	 code - exception code
//				 codePtr - destination pointer
//
// return: always 1
//
// note:	 don't call this directly; use the SetExceptCode macro instead
//
///////////////////////////////////////////////////////////////////////////////

int SaveExceptionCode(DWORD code, PDWORD codePtr)
{
  if (codePtr)
    *codePtr = code;

  return 1;
}


///////////////////////////////////////////////////////////////////////////////
//
// copies exception information
//
// param:	 exception - pointer to the exception information
//				 exceptPtr - destination pointer
//
// return: always 1
//
// note:	 don't call this directly; use the SetExceptInfo macro instead
//
///////////////////////////////////////////////////////////////////////////////

int SaveExceptionInformation(PEXCEPTION_POINTERS exception,
                             PEXCEPTION_POINTERS exceptPtr)
{
  if (exceptPtr)
    if (exception) {
      CopyMemory(exceptPtr->ExceptionRecord, exception->ExceptionRecord,
                 sizeof(EXCEPTION_RECORD));
      CopyMemory(exceptPtr->ContextRecord, exception->ContextRecord,
                 sizeof(CONTEXT));
    } else {
      ZeroMemory(exceptPtr->ExceptionRecord, sizeof(EXCEPTION_RECORD));
      ZeroMemory(exceptPtr->ContextRecord, sizeof(CONTEXT));
    }

  return 1;
}

