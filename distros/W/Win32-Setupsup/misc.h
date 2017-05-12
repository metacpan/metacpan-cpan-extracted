#ifndef __MISC_H
#define __MISC_H

#include <windows.h>


///////////////////////////////////////////////////////////////////////////////
//
// functions
//
///////////////////////////////////////////////////////////////////////////////

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

PSTR NewMem(DWORD size);

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

PSTR NewMem(PVOID oldPtr, DWORD size, int reinit);

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

PSTR NewStr(PSTR str);

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

PWSTR NewStr(PWSTR str);

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

PWSTR NewStrAsWide(PSTR str);

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

int FreeMem(PVOID ptr);

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

int FreeArray(PVOID *ptr, DWORD size);

///////////////////////////////////////////////////////////////////////////////
//
// copies exception code
//
// param:	 code		 - exception code
//				 codePtr - destination pointer
//
// return: always 1
//
// note:	 don't call this directly; use the SetExceptCode macro instead
//
///////////////////////////////////////////////////////////////////////////////

int SaveExceptionCode(DWORD code, PDWORD codePtr);

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
                             PEXCEPTION_POINTERS exceptPtr);


///////////////////////////////////////////////////////////////////////////////
//
// macros
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// gets the exception code and copies it to the except variable
//
///////////////////////////////////////////////////////////////////////////////

#define SetExceptCode(except) SaveExceptionCode(GetExceptionCode(), &except)

///////////////////////////////////////////////////////////////////////////////
//
// gets the exception information and copies it to the except variable
//
///////////////////////////////////////////////////////////////////////////////

#define SetExceptInfo(except) SaveExceptionInformation(GetExceptionInformation(), &except)

///////////////////////////////////////////////////////////////////////////////
//
// defines the variables error, excode and result
//
///////////////////////////////////////////////////////////////////////////////

#define ErrorAndResult  DWORD error = 0, excode = 0; BOOL result = TRUE;

///////////////////////////////////////////////////////////////////////////////
//
// defines the variables except, context and exception
//
///////////////////////////////////////////////////////////////////////////////

#define ExceptInfo EXCEPTION_RECORD except; CONTEXT context;    \
  EXCEPTION_POINTERS exception = {&except, &context};           \
  ZeroMemory(&except, sizeof(except));                          \
  ZeroMemory(&context, sizeof(context));

///////////////////////////////////////////////////////////////////////////////
//
// gets the last error, sets result to false and generates an exception
//
///////////////////////////////////////////////////////////////////////////////

#define RaiseFalse()                                    \
  ( ( error = GetLastError() ), ( result = FALSE ),     \
    ( RaiseException(0xEFFFFFFF, 0, 0, NULL) ) )

///////////////////////////////////////////////////////////////////////////////
//
// gets the last error, sets result to true and generates an exception
//
///////////////////////////////////////////////////////////////////////////////

#define RaiseTrue()                                     \
  ( ( error = GetLastError() ), ( result = TRUE ),      \
    ( RaiseException(0xEFFFFFFF, 0, 0, NULL) ) )

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error, sets result to false and generates an exception
//
///////////////////////////////////////////////////////////////////////////////

#define RaiseFalseError(errorNo) ( SetLastError(error = errorNo), RaiseFalse() )

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error, sets result to true and generates an exception
//
///////////////////////////////////////////////////////////////////////////////

#define RaiseTrueError(errorNo) ( SetLastError(error = errorNo), RaiseTrue() )

///////////////////////////////////////////////////////////////////////////////
//
// gets the last error, sets result to false and leaves
//
///////////////////////////////////////////////////////////////////////////////

#define LeaveFalse()                                    \
  { error = GetLastError(); result = FALSE; __leave; }

///////////////////////////////////////////////////////////////////////////////
//
// gets the last error, sets result to true and leaves
//
///////////////////////////////////////////////////////////////////////////////

#define LeaveTrue()                                     \
  { error = GetLastError(); result = TRUE; __leave; }

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error, sets result to false and leaves
//
///////////////////////////////////////////////////////////////////////////////

#define LeaveFalseError(errorNo) { SetLastError(error = errorNo); LeaveFalse(); }

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error, sets result to true and leaves
//
///////////////////////////////////////////////////////////////////////////////

#define LeaveTrueError(errorNo) { SetLastError(error = errorNo); LeaveTrue(); }

///////////////////////////////////////////////////////////////////////////////
//
// sets the lastError variable
//
///////////////////////////////////////////////////////////////////////////////

#define SetErrorVar()                                           \
  ( lastError ? ( *lastError = error ? error : excode ) : 0 )

///////////////////////////////////////////////////////////////////////////////
//
// resets the lastError variable to null
//
///////////////////////////////////////////////////////////////////////////////

#define ResetErrorVar() ( lastError ? *lastError = 0 : 0 )

///////////////////////////////////////////////////////////////////////////////
//
// macros to clean up resources; there are always three macros:
// Clean*				- frees the resource and sets the resource to null
// Clean*OnErr	- calls Clean* if the error variable is set
// Clean*OnCond	-	calls Clean* if the condition is true
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// closes an handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanHandle(handle)                                             \
  ( ( ( handle ) ? ( CloseHandle(handle), handle = NULL, 1 ) : 1 ) )

#define CleanHandleOnErr(handle)                        \
  ( ( ( error ) ? ( CleanHandle(handle) ) : 1 ) )

#define CleanHandleOnCond(handle, cond)                 \
  ( ( ( cond ) ? ( CleanHandle(handle) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// closes a file handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanFileHandle(handle)                                         \
  ( ( ( handle != INVALID_HANDLE_VALUE) ?                               \
      ( CloseHandle(handle), handle = INVALID_HANDLE_VALUE, 1 ) : 1 ) )

#define CleanFileHandleOnErr(handle)                    \
  ( ( ( error ) ? ( CleanFileHandle(handle) ) : 1 ) )

#define CleanFileHandleOnCond(handle, cond)             \
  ( ( ( cond ) ? ( CleanFileHandle(handle) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// closes a lsa handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanLsaHandle(handle)                                          \
  ( ( ( handle ) ? ( LsaClose(handle), handle = NULL, 1 ) : 1 ) )

#define CleanLsaHandleOnErr(handle)                     \
  ( ( ( error ) ? ( CleanLsaHandle(handle) ) : 1 ) )

#define CleanLsaHandleOnCond(handle, cond)              \
  ( ( ( cond ) ? ( CleanLsaHandle(handle) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a lsa buffer
//
///////////////////////////////////////////////////////////////////////////////

#define CleanLsaPtr(ptr)                                        \
  ( ( ( ptr ) ? ( LsaFreeMemory(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanLsaPtrOnErr(ptr)                   \
  ( ( ( error ) ? ( CleanLsaPtr(ptr) ) : 1 ) )

#define CleanLsaPtrOnCond(ptr, cond)            \
  ( ( ( cond ) ? ( CleanLsaPtr(ptr) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// closes a registry key
//
///////////////////////////////////////////////////////////////////////////////

#define CleanKey(key)                                           \
  ( ( ( key ) ? ( RegCloseKey(key), key = NULL, 1 ) : 1 ) )

#define CleanKeyOnErr(key)                      \
  ( ( ( error ) ? ( CleanKey(key) ) : 1 ) )

#define CleanKeyOnCond(key, cond)               \
  ( ( ( cond ) ? ( CleanKey(key) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a sid
//
///////////////////////////////////////////////////////////////////////////////

#define CleanSid(sid)                                   \
  ( ( ( sid ) ? ( FreeSid(sid), sid = NULL, 1 ) : 1 ) )

#define CleanSidOnErr(sid)                      \
  ( ( ( error ) ? ( CleanSid(sid) ) : 1 ) )

#define CleanSidOnCond(sid, cond)               \
  ( ( ( cond ) ? ( CleanSid(sid) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a buffer allocated by a lanman function
//
///////////////////////////////////////////////////////////////////////////////

#define CleanNetBuf(ptr)                                                \
  ( ( ( ptr ) ? ( NetApiBufferFree(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanNetBufOnErr(ptr)                   \
  ( ( ( error ) ? ( CleanNetBuf(ptr) ) : 1 ) )

#define CleanNetBufOnCond(ptr, cond)            \
  ( ( ( cond ) ? ( CleanNetBuf(ptr) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a library handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanLibrary(lib)                                       \
  ( ( ( lib ) ? ( FreeLibrary(lib), lib = NULL, 1 ) : 1 ) )

#define CleanLibraryOnErr(lib)                  \
  ( ( ( error ) ? ( CleanLibrary(lib) ) : 1 ) )

#define CleanLibraryOnCond(lib, cond)           \
  ( ( ( cond ) ? ( CleanLibrary(lib) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a pointer
//
///////////////////////////////////////////////////////////////////////////////

#define CleanPtr(ptr)                                   \
  ( ( ( ptr ) ? ( FreeMem(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanPtrOnErr(ptr)                      \
  ( ( ( error ) ? ( CleanPtr(ptr) ) : 1 ) )

#define CleanPtrOnCond(ptr, cond)               \
  ( ( ( cond ) ? ( CleanPtr(ptr) ) : 1 ) )


///////////////////////////////////////////////////////////////////////////////
//
// overwrites a buffer and frees the buffer pointer
//
///////////////////////////////////////////////////////////////////////////////

#define ZeroAndCleanPtr(ptr, size)                                      \
  ( ( ( ptr ) ? ( ZeroMemory(ptr, size), FreeMem(ptr), ptr = NULL, 1 ) : 1 ) )

#define ZeroAndCleanPtrOnErr(ptr, size)                         \
  ( ( ( error ) ? ( ZeroAndCleanPtr(ptr, size) ) : 1 ) )

#define ZeroAndCleanPtrOnCond(ptr, size, cond)          \
  ( ( ( cond ) ? ( ZeroAndCleanPtr(ptr, size) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees an array of pointers and the pointer itself
//
///////////////////////////////////////////////////////////////////////////////

#define CleanPtrs(ptr, size)                                            \
  ( ( ( ptr ) ? ( FreeArray((PVOID*)ptr, size), FreeMem(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanPtrsOnErr(ptr, size)                       \
  ( ( ( error ) ? ( CleanPtrs(ptr, size) ) : 1 ) )

#define CleanPtrsOnCond(ptr, size, cond)                \
  ( ( ( cond ) ? ( CleanPtrs(ptr, size) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees an array of pointers
//
///////////////////////////////////////////////////////////////////////////////

#define CleanArray(ptr, size)                                   \
  ( ( ( ptr ) ? ( FreeArray((PVOID*)ptr, size), 1 ) : 1 ) )

#define CleanArrayOnErr(ptr, size)                      \
  ( ( ( error ) ? ( CleanArray(ptr, size) ) : 1 ) )

#define CleanArrayOnCond(ptr, size, cond)               \
  ( ( ( cond ) ? ( CleanArray(ptr, size) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// frees a pointer allocated by SysAllocString
//
///////////////////////////////////////////////////////////////////////////////

#define CleanSysPtr(ptr)                                        \
  ( ( ( ptr ) ? ( SysFreeString(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanSysPtrOnErr(ptr)                   \
  ( ( ( error ) ? ( CleanSysPtr(ptr) ) : 1 ) )

#define CleanSysPtrOnCond(ptr, cond)            \
  ( ( ( cond ) ? ( CleanSysPtr(ptr) ) : 1 ) )


///////////////////////////////////////////////////////////////////////////////
//
// closes an eventlog handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanEventLog(handle)                                           \
  ( ( ( handle ) ? ( DeregisterEventSource(handle), handle = NULL, 1 ) : 1 ) )

#define CleanEventLogOnErr(handle)                      \
  ( ( ( error ) ? ( CleanEventLog(handle) ) : 1 ) )

#define CleanEventLogOnCond(handle, cond)               \
  ( ( ( cond ) ? ( CleanEventLog(handle) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// closes a service control manager or service handle
//
///////////////////////////////////////////////////////////////////////////////

#define CleanServiceHandle(handle)                                      \
  ( ( ( handle ) ? ( CloseServiceHandle(handle), handle = NULL, 1 ) : 1 ) )

#define CleanServiceHandleOnErr(handle)                         \
  ( ( ( error ) ? ( CleanServiceHandle(handle) ) : 1 ) )

#define CleanServiceHandleOnCond(handle, cond)          \
  ( ( ( cond ) ? ( CleanServiceHandle(handle) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// ends a thread
//
///////////////////////////////////////////////////////////////////////////////

#define CleanThread(thread, exit)                                       \
  ( ( ( thread ) ? ( TerminateThread(thread, exit), thread = NULL, 1 ) : 1 ) )

#define CleanThreadOnErr(thread, exit)                  \
  ( ( ( error ) ? ( CleanThread(thread, exit) ) : 1 ) )

#define CleanThreadOnCond(thread, exit, cond)           \
  ( ( ( cond ) ? ( CleanThread(thread, exit) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// ends a thread array
//
///////////////////////////////////////////////////////////////////////////////

#define CleanThreadArray(thread, exit, size)                            \
  { for(int count = 0; count < size; count++) CleanThread(thread[count], exit); \
    CleanPtr(thread); }

#define CleanThreadArrayOnErr(thread, exit, size)       \
  { if( error ) CleanThreadArray(thread, exit, size); }

#define CleanThreadArrayOnCond(thread, exit, size, cond)        \
  { if( cond ) CleanThreadArray(thread, exit, size); }

///////////////////////////////////////////////////////////////////////////////
//
// frees a buffer allocated by a terminal server function
//
///////////////////////////////////////////////////////////////////////////////

#define CleanWtsBuf(ptr)                                                \
  ( ( ( ptr && WTSFreeMemoryCall ) ? ( WTSFreeMemoryCall(ptr), ptr = NULL, 1 ) : 1 ) )

#define CleanWtsBufOnErr(ptr)                   \
  ( ( ( error ) ? ( CleanWtsBuf(ptr) ) : 1 ) )

#define CleanWtsBufOnCond(ptr)                  \
  ( ( ( cond ) ? ( CleanWtsBuf(ptr) ) : 1 ) )

///////////////////////////////////////////////////////////////////////////////
//
// closes an ip socket
//
///////////////////////////////////////////////////////////////////////////////

#define CleanSocket(sock)                                               \
  ( ( ( sock != INVALID_SOCKET ) ? ( shutdown(sock, SD_BOTH), sock = INVALID_SOCKET, 1 ) : 1 ) )

#define CleanSocketOnErr(sock)                  \
  ( ( ( error ) ? ( CleanSocket(sock) ) : 1 ) )

#define CleanSocketOnCond(sock)                 \
  ( ( ( cond ) ? ( CleanSocket(sock) ) : 1 ) )


///////////////////////////////////////////////////////////////////////////////
//
// returns the size of an array
//
///////////////////////////////////////////////////////////////////////////////

#define array_size(array) ( sizeof(array) / sizeof(array[0]) )


///////////////////////////////////////////////////////////////////////////////
//
// initializes, deletes, enters and leaves critical section objects
//
///////////////////////////////////////////////////////////////////////////////

#define CARE_INIT_CRIT_SECT(sect)                                       \
  ( !( (sect)->DebugInfo ) || IsBadCodePtr( (FARPROC) ( (sect)->DebugInfo ) )  ? \
    InitializeCriticalSection(sect) : (void)0 )

#define CARE_DEL_CRIT_SECT(sect)                                        \
  ( !IsBadCodePtr( (FARPROC) ( (sect)->DebugInfo ) ) ? DeleteCriticalSection(sect) : (void)0, \
    ZeroMemory( sect, sizeof(*sect) )  )

#define CARE_ENTER_CRIT_SECT(sect)                              \
  ( CARE_INIT_CRIT_SECT(sect), EnterCriticalSection(sect) )

#define CARE_TRY_ENTER_CRIT_SECT(sect)                          \
  ( CARE_INIT_CRIT_SECT(sect), TryEnterCriticalSection(sect) )

#define CARE_LEAVE_CRIT_SECT(sect)                                      \
  ( ( (sect)->DebugInfo ? 0 : InitializeCriticalSection(sect) ), LeaveCriticalSection(sect) )


#endif // #ifndef __MISC_H
