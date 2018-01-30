
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <wincrypt.h> /* needed for crypt_gen_random
                         but not for rtl_gen_random */

void print_error(pTHX) {

  dSP;
  PUSHMARK(SP);
  call_pv("Win32::GenRandom::_system_error", G_DISCARD|G_NOARGS);
}

void cgr(pTHX_ SV * x, ...) {

  dXSARGS;
  unsigned long i;
  BYTE * buff;
  HCRYPTPROV prov = 0;
  unsigned long how_many;
  DWORD len;

  if(items == 1) {
    how_many = 1;
    len = (ULONG)SvUV(ST(0));
  }
  else {
    if(items == 2) {
      how_many = (unsigned long)SvUV(ST(0));
      len = (ULONG)SvUV(ST(1));
    }
    else croak("cgr takes either 1 or 2 args, not %d", items);
  }

  if(!CryptAcquireContextA(&prov, NULL, NULL, PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT)) {
    warn("Call to CryptAcquireContextA failed\n");
    print_error(aTHX); /* callback to $^E */
    croak("Croaking - owing to failure of CryptAcquireContextA");
  }

  Newx(buff, len + 1, BYTE);
  if(buff == NULL) {
    warn ("Failed to allocate memory for buffer");
    CryptReleaseContext(prov, 0);
    croak("Croaking - owing to memory allocation failure");
  }

  sp = mark;

  for(i = 0; i < how_many; i++) {
    if(!CryptGenRandom(prov, len, buff)) {
      warn("Call to CryptGenRandom failed");
      Safefree(buff);
      CryptReleaseContext(prov, 0);
      print_error(aTHX); /* callback to $^E */
      croak("Croaking - owing to failure of call to CryptGenRandom");
    }
    XPUSHs(sv_2mortal(newSVpv(buff, len)));
  }
  Safefree(buff);
  CryptReleaseContext(prov, 0);
  PUTBACK;
  XSRETURN(how_many);
}

void cgr_custom(pTHX_ SV * x, ...) {

  dXSARGS;
  unsigned long i;
  BYTE * buff;
  HCRYPTPROV prov = 0;
  unsigned long how_many;
  DWORD len;
  int offset = 0;

  if(items == 5) {
    how_many = 1;
    len = (ULONG)SvUV(ST(0));
  }
  else {
    if(items == 6) {
      how_many = (unsigned long)SvUV(ST(0));
      len = (ULONG)SvUV(ST(1));
      offset = 1;
    }
    else croak("cgr_custom takes either 5 or 6 args, not %d", items);
  }

  if(!CryptAcquireContextA(&prov, SvPV_nolen(ST(offset + 1)), SvPV_nolen(ST(offset + 2)),
                           (DWORD)SvUV(ST(offset + 3)), (DWORD)SvUV(ST(offset + 4)))) {
    warn("Call to CryptAcquireContextA failed\n");
    print_error(aTHX); /* callback to $^E */
    croak("Croaking - owing to failure of CryptAcquireContextA");
  }

  Newx(buff, len + 1, BYTE);
  if(buff == NULL) {
    warn ("Failed to allocate memory for buffer");
    CryptReleaseContext(prov, 0);
    croak("Croaking - owing to memory allocation failure");
  }

  sp = mark;

  for(i = 0; i < how_many; i++) {
    if(!CryptGenRandom(prov, len, buff)) {
      warn("Call to CryptGenRandom failed");
      Safefree(buff);
      CryptReleaseContext(prov, 0);
      print_error(aTHX); /* callback to $^E */
      croak("Croaking - owing to failure of call to CryptGenRandom");
    }
    XPUSHs(sv_2mortal(newSVpv(buff, len)));
  }
  Safefree(buff);
  CryptReleaseContext(prov, 0);
  PUTBACK;
  XSRETURN(how_many);
}

void rgr(pTHX_ SV * x, ...) {
#ifndef WIN2K
  dXSARGS;
  unsigned long i;
  BYTE * buff;
  unsigned long how_many;
  ULONG len;
  HMODULE hLib;

  if(items == 1) {
    how_many = 1;
    len = (ULONG)SvUV(ST(0));
  }
  else {
    if(items == 2) {
      how_many = (unsigned long)SvUV(ST(0));
      len = (ULONG)SvUV(ST(1));
    }
    else croak("rgr takes either 1 or 2 args, not %d", items);
  }

  Newx(buff, len + 1, BYTE);
  if(buff == NULL) croak ("Failed to allocate memory for 'buff'");

  hLib = LoadLibrary("ADVAPI32.DLL");

  sp = mark;

  if (hLib) {
    BOOLEAN (APIENTRY *pfn)(void*, ULONG) =
      (BOOLEAN (APIENTRY *)(void*,ULONG))GetProcAddress(hLib,"SystemFunction036");

    for(i = 0; i < how_many; i++) {
      if(pfn(buff,len)) {
        XPUSHs(sv_2mortal(newSVpv(buff, len)));
       /*
          Now that we've finished with it, fill buffer with zeroes (as per MSDN recommendation).
          We do this with SecureZeroMemory if its available, else we do it with ZeroMemory if
          it's available, else we don't do it.
       */
#ifdef  SecureZeroMemory
        SecureZeroMemory(buff, len);
#else
#ifdef  ZeroMemory
        ZeroMemory(buff, len);
#endif
#endif
      }
      else {
        warn("Call to 'SystemFunction036' failed");
        FreeLibrary(hLib);
        print_error(aTHX); /* callback to $^E */
        croak("Croaking - owing to failure of call to 'SystemFunction036'");
      }
    }

    FreeLibrary(hLib);
  }

  else {
    print_error(aTHX); /* callback to $^E */
    croak("Failed to load ADVAPI32.dll");
  }

  Safefree(buff);
  PUTBACK;
  XSRETURN(how_many);

# else
  croak("RtlGenRandom not available on Windows 2000 - use CryptGenRandom instead");
#endif

}

SV * _error_test(pTHX) {
  /* Solely for use of test suite */
  HMODULE hLib=LoadLibrary("NO_SUCH.DLL");
  if(hLib) return newSVuv(0);
  else print_error(aTHX);
  return newSVuv(42);
}

/* FLAGS */


SV * _CRYPT_DEFAULT_CONTAINER_OPTIONAL(pTHX) {
#ifdef CRYPT_DEFAULT_CONTAINER_OPTIONAL
  return newSVuv(CRYPT_DEFAULT_CONTAINER_OPTIONAL);
#else
  return &PL_sv_undef;
#endif
}

SV * _CRYPT_SILENT(pTHX) {
#ifdef CRYPT_SILENT
  return newSVuv(CRYPT_SILENT);
#else
  return &PL_sv_undef;
#endif
}

SV * _CRYPT_DELETEKEYSET(pTHX) {
#ifdef CRYPT_DELETEKEYSET
  return newSVuv(CRYPT_DELETEKEYSET);
#else
  return &PL_sv_undef;
#endif
}

SV * _CRYPT_MACHINE_KEYSET(pTHX) {
#ifdef CRYPT_MACHINE_KEYSET
  return newSVuv(CRYPT_MACHINE_KEYSET);
#else
  return &PL_sv_undef;
#endif
}

SV * _CRYPT_NEWKEYSET(pTHX) {
#ifdef CRYPT_NEWKEYSET
  return newSVuv(CRYPT_NEWKEYSET);
#else
  return &PL_sv_undef;
#endif
}

SV * _CRYPT_VERIFYCONTEXT(pTHX) {
#ifdef CRYPT_VERIFYCONTEXT
  return newSVuv(CRYPT_VERIFYCONTEXT);
#else
  return &PL_sv_undef;
#endif
}

/* PROVIDER TYPES */

SV * _PROV_RSA_FULL(pTHX) {
#ifdef PROV_RSA_FULL
  return newSVuv(PROV_RSA_FULL);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_RSA_AES(pTHX) {
#ifdef PROV_RSA_AES
  return newSVuv(PROV_RSA_AES);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_RSA_SIG(pTHX) {
#ifdef PROV_RSA_SIG
  return newSVuv(PROV_RSA_SIG);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_RSA_SCHANNEL(pTHX) {
#ifdef PROV_RSA_SCHANNEL
  return newSVuv(PROV_RSA_SCHANNEL);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_DSS(pTHX) {
#ifdef PROV_DSS
  return newSVuv(PROV_DSS);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_DSS_DH(pTHX) {
#ifdef PROV_DSS_DH
  return newSVuv(PROV_DSS_DH);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_DH_SCHANNEL(pTHX) {
#ifdef PROV_DH_SCHANNEL
  return newSVuv(PROV_DH_SCHANNEL);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_FORTEZZA(pTHX) {
#ifdef PROV_FORTEZZA
  return newSVuv(PROV_FORTEZZA);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_MS_EXCHANGE(pTHX) {
#ifdef PROV_MS_EXCHANGE
  return newSVuv(PROV_MS_EXCHANGE);
#else
  return &PL_sv_undef;
#endif
}

SV * _PROV_SSL(pTHX) {
#ifdef PROV_SSL
  return newSVuv(PROV_SSL);
#else
  return &PL_sv_undef;
#endif
}

SV * whw(pTHX) {
#ifdef SecureZeroMemory
       return newSVpv("SecureZeroMemory", 0);
#else
#ifdef ZeroMemory
       return newSVpv("ZeroMemory", 0);
#else
       return newSVpv("None", 0);
#endif
#endif
}

/*
DWORD WINAPI GetLastError(void);
HRESULT HRESULT_FROM_WIN32(DWORD x);

BOOL WINAPI CryptAcquireContext(
  _Out_  HCRYPTPROV *phProv,
  _In_   LPCTSTR pszContainer,
  _In_   LPCTSTR pszProvider,
  _In_   DWORD dwProvType,
  _In_   DWORD dwFlags
);

BOOL WINAPI CryptGenRandom(
  _In_     HCRYPTPROV hProv,
  _In_     DWORD dwLen,
  _Inout_  BYTE *pbBuffer
);

BOOLEAN RtlGenRandom(
  _Out_  PVOID RandomBuffer,
  _In_   ULONG RandomBufferLength
);

*/

MODULE = Win32::GenRandom  PACKAGE = Win32::GenRandom

PROTOTYPES: DISABLE


void
print_error ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        print_error(aTHX);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cgr (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cgr(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cgr_custom (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cgr_custom(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
rgr (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        rgr(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_error_test ()
CODE:
  RETVAL = _error_test (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_DEFAULT_CONTAINER_OPTIONAL ()
CODE:
  RETVAL = _CRYPT_DEFAULT_CONTAINER_OPTIONAL (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_SILENT ()
CODE:
  RETVAL = _CRYPT_SILENT (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_DELETEKEYSET ()
CODE:
  RETVAL = _CRYPT_DELETEKEYSET (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_MACHINE_KEYSET ()
CODE:
  RETVAL = _CRYPT_MACHINE_KEYSET (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_NEWKEYSET ()
CODE:
  RETVAL = _CRYPT_NEWKEYSET (aTHX);
OUTPUT:  RETVAL


SV *
_CRYPT_VERIFYCONTEXT ()
CODE:
  RETVAL = _CRYPT_VERIFYCONTEXT (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_RSA_FULL ()
CODE:
  RETVAL = _PROV_RSA_FULL (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_RSA_AES ()
CODE:
  RETVAL = _PROV_RSA_AES (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_RSA_SIG ()
CODE:
  RETVAL = _PROV_RSA_SIG (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_RSA_SCHANNEL ()
CODE:
  RETVAL = _PROV_RSA_SCHANNEL (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_DSS ()
CODE:
  RETVAL = _PROV_DSS (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_DSS_DH ()
CODE:
  RETVAL = _PROV_DSS_DH (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_DH_SCHANNEL ()
CODE:
  RETVAL = _PROV_DH_SCHANNEL (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_FORTEZZA ()
CODE:
  RETVAL = _PROV_FORTEZZA (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_MS_EXCHANGE ()
CODE:
  RETVAL = _PROV_MS_EXCHANGE (aTHX);
OUTPUT:  RETVAL


SV *
_PROV_SSL ()
CODE:
  RETVAL = _PROV_SSL (aTHX);
OUTPUT:  RETVAL


SV *
whw ()
CODE:
  RETVAL = whw (aTHX);
OUTPUT:  RETVAL


