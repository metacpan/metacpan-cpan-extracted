#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Win32::Resources		PACKAGE = Win32::Resources		

PROTOTYPES: DISABLE

int
_MakeLangId(...)
CODE:
	int Language;

	if (items == 1) {
		Language = SvIV(ST(0));
	} else {
		Language = MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL);
	}

	RETVAL = Language;
OUTPUT:
	RETVAL

void
_LoadResource(szFileName, obType, obName, Language)
	LPCSTR szFileName
	SV* obType
	SV* obName
	SV* Language
PPCODE:
	HMODULE hModule;
	LPCTSTR lpType;
	LPCTSTR lpName;
	WORD wLanguage;
	HRSRC hrsrc;
	DWORD size;
	HGLOBAL hglob;
	LPVOID p;
	int library = 0;

	hModule = LoadLibraryEx(szFileName, 0, LOAD_LIBRARY_AS_DATAFILE);
	if (hModule == NULL)
		hModule = GetModuleHandle(NULL);
	else
		library = 1;

	if (hModule == NULL) goto end;

	wLanguage = (WORD) SvIV(Language);

	if (SvIOK(obType))
		lpType = MAKEINTRESOURCE(SvIV(obType));
	else if (SvPOK(obType))
		lpType = SvPV_nolen(obType);
	else
		goto end;

	if (SvIOK(obName))
		lpName = MAKEINTRESOURCE(SvIV(obName));
	else if (SvPOK(obName))
		lpName = SvPV_nolen(obName);
	else
		goto end;

	hrsrc = FindResourceEx(hModule, lpType, lpName, wLanguage);
	if (hrsrc == NULL) goto end;

	size = SizeofResource(hModule, hrsrc);
	if (size == 0) goto end;

	hglob = LoadResource(hModule, hrsrc);
	if (hglob == NULL) goto end;

	p = LockResource(hglob);
	if (p == NULL) goto end;

	XPUSHs(sv_2mortal(newSVpvn(p, size)));
	XSRETURN(1);
end:
	if (library == 1) FreeLibrary(hModule);
	XSRETURN_UNDEF;

void
_BeginUpdateResource(szFileName, bDeleteExistingResources)
	LPCSTR szFileName
	int bDeleteExistingResources
PPCODE:
	HANDLE h = BeginUpdateResource(szFileName, bDeleteExistingResources);
	if (h == NULL) XSRETURN_UNDEF;

	XPUSHs(newSViv((int)h));
	XSRETURN(1);

void
_UpdateResource(hUpdate, obType, obName, Language, lpData, cbData)
	HMODULE hUpdate
	SV* obType
	SV* obName
	SV* Language
	LPVOID lpData
	DWORD cbData
PPCODE:
	LPCTSTR lpType;
	LPCTSTR lpName;
	BOOL ok;
	WORD wLanguage;

	wLanguage = (WORD) SvIV(Language);

	if (SvIOK(obType))
		lpType = MAKEINTRESOURCE(SvIV(obType));
	else if (SvPOK(obType))
		lpType = SvPV_nolen(obType);
	else
		XSRETURN_UNDEF;

	if (SvIOK(obName))
		lpName = MAKEINTRESOURCE(SvIV(obName));
	else if (SvPOK(obName))
		lpName = SvPV_nolen(obName);
	else
		XSRETURN_UNDEF;

	ok = UpdateResource(hUpdate, lpType, lpName, wLanguage, lpData, cbData);
	if (!ok) XSRETURN_UNDEF;

	XSRETURN_YES;

void
_EndUpdateResource(hUpdate, fDiscard)
	HMODULE hUpdate
	int fDiscard
PPCODE:
	if (!EndUpdateResource(hUpdate, fDiscard)) XSRETURN_UNDEF;

	XSRETURN_YES;
