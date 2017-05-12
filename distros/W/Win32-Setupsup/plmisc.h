#ifndef __PLMISC_H
#define __PLMISC_H


// perl 5.003_07 build 316
#ifdef PERL_5003_07

  #ifndef PERL_OBJECT
          #define PERL_OBJECT
  #endif

  #define PERL_CALL_SINGLE        CPerl   *pPerl
  #define PERL_CALL               CPerl   *pPerl,
  #define P_PERL                  pPerl,
  #define P_PERL_SINGLE           pPerl

  #define PL_na                   na
  #define PL_sv_yes               sv_yes
  #define PL_sv_no                sv_no

#endif

// perl 5.005_03 build 522
#ifdef PERL_5005_03

  #ifndef PERL_OBJECT
          #define PERL_OBJECT
  #endif

  #define PERL_CALL_SINGLE        CPerl   *pPerl
  #define PERL_CALL               CPerlObj *pPerl,
  #define P_PERL                  pPerl,
  #define P_PERL_SINGLE           pPerl

  #define CPerl                   CPerlObj

#endif

// perl 5.6.0 build 613
#ifdef PERL_5_6_0

  #ifdef PERL_OBJECT
    #undef PERL_OBJECT
  #endif

  #define PERL_CALL_SINGLE
  #define PERL_CALL
  #define P_PERL
  #define P_PERL_SINGLE

#endif

#define ssize_t int

// must be defined to avoid duplicate linker symbols
#ifndef __PLMISC_CPP
#define __XSlock_h__
#endif


#include "extern.h"
#include "perl.h"
#include "xsub.h"

#include "wstring.h"
#include "misc.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

// set result and return
#define RETURNRESULT(x) { if((x)) { XST_mYES(0); } else { XST_mNO(0); } XSRETURN(1); }

// get strings, int's, hashes or arrays from array, hash or scalar
#define A_FETCH_WSTR(array, idx)                        WStrFromArray(P_PERL array, idx, FALSE)
#define A_FETCH_STR(array, idx)                         StrFromArray(P_PERL array, idx, FALSE)
#define A_FETCH_SLEN(array, idx)                        SLenFromArray(P_PERL array, idx, FALSE)
#define A_FETCH_SIZE(array, idx)                        (SLenFromArray(P_PERL array, idx, FALSE) + 1)
#define A_FETCH_PTR(array, idx, len)    PtrFromArray(P_PERL array, idx, (unsigned*)&len, FALSE)
#define A_FETCH_INT(array, idx)                         IntFromArray(P_PERL array, idx, FALSE)
#define A_FETCH_HASH(array, idx)                        HashFromArray(P_PERL array, idx, FALSE, FALSE)
#define A_FETCH_RHASH(array, idx)                       HashFromArray(P_PERL array, idx, FALSE, TRUE)
#define A_FETCH_ARRAY(array, idx)                       ArrayFromArray(P_PERL array, idx, FALSE, FALSE)
#define A_FETCH_RARRAY(array, idx)              ArrayFromArray(P_PERL array, idx, FALSE, TRUE)

#define AR_FETCH_WSTR(array, idx)                       WStrFromArray(P_PERL array, idx, TRUE)
#define AR_FETCH_STR(array, idx)                        StrFromArray(P_PERL array, idx, TRUE)
#define AR_FETCH_SLEN(array, idx)               SLenFromArray(P_PERL array, idx, TRUE)
#define AR_FETCH_SIZE(array, idx)               (SLenFromArray(P_PERL array, idx, TRUE) + 1)
#define AR_FETCH_PTR(array, idx, len)   PtrFromArray(P_PERL array, idx, (unsigned*)&len, TRUE)
#define AR_FETCH_INT(array, idx)                        IntFromArray(P_PERL array, idx, TRUE)
#define AR_FETCH_HASH(array, idx)                       HashFromArray(P_PERL array, idx, TRUE, FALSE)
#define AR_FETCH_RHASH(array, idx)              HashFromArray(P_PERL array, idx, TRUE, TRUE)
#define AR_FETCH_ARRAY(array, idx)              ArrayFromArray(P_PERL array, idx, TRUE, FALSE)
#define AR_FETCH_RARRAY(array, idx)             ArrayFromArray(P_PERL array, idx, TRUE, TRUE)

#define H_FETCH_WSTR(hash, idx)                         WStrFromHash(P_PERL hash, idx, FALSE)
#define H_FETCH_STR(hash, idx)                          StrFromHash(P_PERL hash, idx, FALSE)
#define H_FETCH_SLEN(hash, idx)                         SLenFromHash(P_PERL hash, idx, FALSE)
#define H_FETCH_SIZE(hash, idx)                         (SLenFromHash(P_PERL hash, idx, FALSE) + 1)
#define H_FETCH_PTR(hash, idx, len)             PtrFromHash(P_PERL hash, idx, (unsigned*)&len, FALSE)
#define H_FETCH_INT(hash, idx)                          IntFromHash(P_PERL hash, idx, FALSE)
#define H_FETCH_HASH(hash, idx)                         HashFromHash(P_PERL hash, idx, FALSE, FALSE)
#define H_FETCH_RHASH(hash, idx)                        HashFromHash(P_PERL hash, idx, FALSE, TRUE)
#define H_FETCH_ARRAY(hash, idx)                        ArrayFromHash(P_PERL hash, idx, FALSE, FALSE)
#define H_FETCH_RARRAY(hash, idx)               ArrayFromHash(P_PERL hash, idx, FALSE, TRUE)

#define HR_FETCH_WSTR(hash, idx)                        WStrFromHash(P_PERL hash, idx, TRUE)
#define HR_FETCH_STR(hash, idx)                         StrFromHash(P_PERL hash, idx, TRUE)
#define HR_FETCH_STR(hash, idx)                         StrFromHash(P_PERL hash, idx, TRUE)
#define HR_FETCH_SLEN(hash, idx)                        SLenFromHash(P_PERL hash, idx, TRUE)
#define HR_FETCH_PTR(hash, idx, len)    PtrFromHash(P_PERL hash, idx, (unsigned*)&len, TRUE)
#define HR_FETCH_INT(hash, idx)                         IntFromHash(P_PERL hash, idx, TRUE)
#define HR_FETCH_HASH(hash, idx)                        HashFromHash(P_PERL hash, idx, TRUE, FALSE)
#define HR_FETCH_RHASH(hash, idx)                       HashFromHash(P_PERL hash, idx, TRUE, TRUE)
#define HR_FETCH_ARRAY(hash, idx)                       ArrayFromHash(P_PERL hash, idx, TRUE, FALSE)
#define HR_FETCH_RARRAY(hash, idx)              ArrayFromHash(P_PERL hash, idx, TRUE, TRUE)

#define S_FETCH_WSTR(scalar)                                    WStrFromScalar(P_PERL scalar, FALSE)
#define S_FETCH_STR(scalar)                                             StrFromScalar(P_PERL scalar, FALSE)
#define S_FETCH_INT(scalar)                                             IntFromScalar(P_PERL scalar, FALSE)
#define S_FETCH_SLEN(scalar)                                    SLenFromScalar(P_PERL scalar, FALSE)
#define S_FETCH_SIZE(scalar)                                    (SLenFromScalar(P_PERL scalar, FALSE) + 1)

#define SR_FETCH_WSTR(scalar)                                   WStrFromScalar(P_PERL scalar, TRUE)
#define SR_FETCH_STR(scalar)                                    StrFromScalar(P_PERL scalar,  TRUE)
#define SR_FETCH_INT(scalar)                                    IntFromScalar(P_PERL scalar, TRUE)
#define SR_FETCH_SLEN(scalar)                                   SLenFromScalar(P_PERL scalar, TRUE)
#define SR_FETCH_SIZE(scalar)                                   (SLenFromScalar(P_PERL scalar, TRUE) + 1)

// put strings or int's to array, hash or scalar
#define H_STORE_WSTR(hash, idx, str)                            WStrToHash(P_PERL hash, idx, str)
#define H_STORE_WNSTR(hash, idx, str, len)      WNStrToHash(P_PERL hash, idx, str, len)
#define H_STORE_STR(hash, idx, str)                                     StrToHash(P_PERL hash, idx, str)
#define H_STORE_PTR(hash, idx, ptr, len)                PtrToHash(P_PERL hash, idx, ptr, len)
#define H_STORE_INT(hash, idx, val)                                     IntToHash(P_PERL hash, idx, val)
#define H_STORE_REF(hash, idx, ptr)                                     RefToHash(P_PERL hash, idx, ptr)

#define A_STORE_WSTR(array, str)                                        WStrToArray(P_PERL array, str)
#define A_STORE_WNSTR(array, str, len)          WNStrToArray(P_PERL array, str, len)
#define A_STORE_STR(array, str)                                         StrToArray(P_PERL array, str)
#define A_STORE_PTR(array, ptr, len)                    PtrToArray(P_PERL array, ptr, len)
#define A_STORE_INT(array, val)                                         IntToArray(P_PERL array, val)
#define A_STORE_REF(array, ptr)                                         RefToArray(P_PERL array, ptr)

#define S_STORE_WSTR(string, str)                                       WStrToScalar(P_PERL string, str)
#define S_STORE_STR(string, str)                                        StrToScalar(P_PERL string, str)
#define S_STORE_PTR(string, ptr, len)                   PtrToScalar(P_PERL string, ptr, len)
#define S_STORE_INT(string, val)                                        IntToScalar(P_PERL string, val)

// checks if a key in an hash exists
#define H_EXISTS(hash, key) (hash && key && hv_exists(hash, key, strlen(key)) ? 1 : 0)

// checks if a key in an hash exists; if the key exists, the value as PWSTR will
// be returned otherwise defaultval
#define H_EXISTS_FETCH_WSTR(hash, key, defaultval)                      \
  (hash && key && hv_exists(hash, key, strlen(key)) ? H_FETCH_WSTR(hash, key) : defaultval)

// checks if a key in an hash exists; if the key exists, the values PSTR will be
// returned otherwise defaultval
#define H_EXISTS_FETCH_STR(hash, key, defaultval)                       \
  (hash && key && hv_exists(hash, key, strlen(key)) ? H_FETCH_STR(hash, key) : defaultval)

// checks if a key in an hash exists; if the key exists, the values int will be
// returned otherwise defaultval
#define H_EXISTS_FETCH_INT(hash, key, defaultval)                       \
  (hash && key && hv_exists(hash, key, strlen(key)) ? H_FETCH_INT(hash, key) : defaultval)

// checks if var is a scalar (int, numerical or string)
#define IS_SCALAR(var)                                          \
  (SvTYPE(var) >= SVt_NULL && SvTYPE(var) <= SVt_PVMG ? 1 : 0)

// checks and assigns an scalar reference to var
#define CHK_ASSIGN_SREF(var, ptr)                                       \
  (ptr && SvROK(var = ptr) && (var = SvRV(var)) && IS_SCALAR(var))

// checks and assigns an array reference to var
#define CHK_ASSIGN_AREF(var, ptr)                                       \
  (ptr && SvROK(var = (AV*)ptr) && (SvTYPE(var = (AV*)SvRV(var)) == SVt_PVAV))

// checks and assigns a hash reference to var
#define CHK_ASSIGN_HREF(var, ptr)                                       \
  (ptr && SvROK(var = (HV*)ptr) && (SvTYPE(var = (HV*)SvRV(var)) == SVt_PVHV))

// creates a new hash; if there is not enougth memory an execption will be raised
#define NewHV NewHash(P_PERL_SINGLE)

// creates a new array; if there is not enougth memory an execption will be raised
#define NewAV NewArray(P_PERL_SINGLE)

// creates a new reference; if there is not enougth memory an execption will be raised
#define NewRV NewReference(P_PERL refobj)

// deletes a scalar
#define SV_CLEAR(scalar) { if(scalar) sv_setpv(scalar, NULL); }

// deletes an hash
#define HV_CLEAR(hash) { if(hash && SvTYPE(hash) == SVt_PVHV) hv_clear(hash); }

// deletes an array
#define AV_CLEAR(array) { if(array && SvTYPE(array) == SVt_PVAV) av_clear(array); }

// gets the array length
#define AV_LEN(array) (array ? av_len(array) : -1)


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// sets the last error variable of the current thread
//
// param:  error        - error value to set
//
// return: last error variable of the current thread
//
///////////////////////////////////////////////////////////////////////////////

DWORD LastError(DWORD error);

///////////////////////////////////////////////////////////////////////////////
//
// returns the last error variable of the current thread
//
// param:
//
// return: last error variable of the current thread
//
///////////////////////////////////////////////////////////////////////////////

DWORD LastError();

///////////////////////////////////////////////////////////////////////////////
//
// get/put strings, pointers and int's from/to hashes, arrays and scalars
// safely
//
///////////////////////////////////////////////////////////////////////////////

PWSTR WStrFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef);

PSTR StrFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef);

int SLenFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef);

PVOID PtrFromHash(PERL_CALL HV *hash, PSTR idx, unsigned *len, BOOL isRef);

int IntFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef);

HV *HashFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef, BOOL convRef);

AV *ArrayFromHash(PERL_CALL HV *hash, PSTR idx, BOOL isRef, BOOL convRef);

PWSTR WStrFromArray(PERL_CALL AV *array, int idx, BOOL isRef);

PSTR StrFromArray(PERL_CALL AV *array, int idx, BOOL isRef);

int SLenFromArray(PERL_CALL AV *array, int idx, BOOL isRef);

PVOID PtrFromArray(PERL_CALL AV *array, int idx, unsigned *len, BOOL isRef);

int IntFromArray(PERL_CALL AV *array, int idx, BOOL isRef);

HV *HashFromArray(PERL_CALL AV *array, int idx, BOOL isRef, BOOL convRef);

AV *ArrayFromArray(PERL_CALL AV *array, int idx, BOOL isRef, BOOL convRef);

PWSTR WStrFromScalar(PERL_CALL SV *string, BOOL isRef);

PSTR StrFromScalar(PERL_CALL SV *string, BOOL isRef);

int SLenFromScalar(PERL_CALL SV *string, BOOL isRef);

int IntFromScalar(PERL_CALL SV *string, BOOL isRef);

int WStrToHash(PERL_CALL HV *hash, PSTR idx, PWSTR str);

int WNStrToHash(PERL_CALL HV *hash, PSTR idx, PWSTR str, DWORD strLen);

int StrToHash(PERL_CALL HV *hash, PSTR idx, PSTR str);

int PtrToHash(PERL_CALL HV *hash, PSTR idx, PVOID ptr, int len);

int IntToHash(PERL_CALL HV *hash, PSTR idx, int val);

int RefToHash(PERL_CALL HV *hash, PSTR idx, PVOID ptr);

int WStrToArray(PERL_CALL AV *array, PWSTR str);

int WNStrToArray(PERL_CALL AV *array, PWSTR str, DWORD strLen);

int StrToArray(PERL_CALL AV *array, PSTR str);

int IntToArray(PERL_CALL AV *array, int val);

int PtrToArray(PERL_CALL AV *array, PVOID ptr, int len);

int RefToArray(PERL_CALL AV *array, PVOID ptr);

int WStrToScalar(PERL_CALL SV *string, PWSTR str);

int StrToScalar(PERL_CALL SV *string, PSTR str);

int IntToScalar(PERL_CALL SV *string, int val);

int PtrToScalar(PERL_CALL SV *string, PVOID ptr, int len);

///////////////////////////////////////////////////////////////////////////////
//
// create new hashes, arrays or references; if there is not enougth memory an
// execption will be raised; use the NewHV/AV/RV macros to call it
//
///////////////////////////////////////////////////////////////////////////////

HV *NewHash(PERL_CALL_SINGLE);

AV *NewArray(PERL_CALL_SINGLE);

SV *NewReference(PERL_CALL SV *refObj);


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// index to access tls space
extern DWORD TlsIndex;


#endif // #ifndef __PLMISC_H
