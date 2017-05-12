#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Win32::MBCS		PACKAGE = Win32::MBCS		

void
Utf8ToLocal(sv)
	SV *sv
 PREINIT:
	LPWSTR lpTemp;
	LPSTR lpSrc, lpDst;
	STRLEN lenSrc, lenTemp, lenDst;
 CODE:
	lenSrc=SvCUR(sv);
	lpSrc=(LPSTR)SvPV_nolen(sv);
	lenTemp=MultiByteToWideChar(CP_UTF8, 0, lpSrc, lenSrc, NULL, NULL);
	New(0, lpTemp, lenTemp, WCHAR);
	MultiByteToWideChar(CP_UTF8, 0, lpSrc, lenSrc, lpTemp, lenTemp);

	lenDst=WideCharToMultiByte(CP_ACP, 0, lpTemp, lenTemp, NULL, NULL, NULL, NULL);
	SvUPGRADE(sv, SVt_PV);
	SvUTF8_off(sv);
	SvGROW(sv, (STRLEN)lenDst);
	lpDst=(LPSTR)SvPV_nolen(sv);
	WideCharToMultiByte(CP_ACP, 0, lpTemp, lenTemp, lpDst, lenDst, NULL, NULL);
	Safefree(lpTemp);

	SvCUR_set(sv, (STRLEN)lenDst);
	SvPOK_on(sv);
 OUTPUT:
    sv

void
LocalToUtf8(sv)
	SV *sv
 PREINIT:
	LPWSTR lpTemp;
	LPSTR lpSrc, lpDst;
	STRLEN lenSrc, lenTemp, lenDst;
 CODE:
	lenSrc=SvCUR(sv);
	lpSrc=(LPSTR)SvPV_nolen(sv);
	lenTemp=MultiByteToWideChar(CP_ACP, 0, lpSrc, lenSrc, NULL, NULL);
	New(0, lpTemp, lenTemp, WCHAR);
	MultiByteToWideChar(CP_ACP, 0, lpSrc, lenSrc, lpTemp, lenTemp);

	lenDst=WideCharToMultiByte(CP_UTF8, 0, lpTemp, lenTemp, NULL, NULL, NULL, NULL);
	SvUPGRADE(sv, SVt_PV);
	SvGROW(sv, (STRLEN)lenDst);
	lpDst=(LPSTR)SvPV_nolen(sv);
	WideCharToMultiByte(CP_UTF8, 0, lpTemp, lenTemp, lpDst, lenDst, NULL, NULL);
	Safefree(lpTemp);

	SvCUR_set(sv, (STRLEN)lenDst);
	SvUTF8_on(sv);
	SvPOK_on(sv);
 OUTPUT:
    sv