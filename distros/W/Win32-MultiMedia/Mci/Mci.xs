#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mmsystem.h>

#define RETMAXSIZE 128

MODULE = Win32::MultiMedia::Mci		PACKAGE = Win32::MultiMedia::Mci		PREFIX=mci

void
mciSendString(lpstrCommand, getres=0)
	 char * lpstrCommand
	 int getres
	PREINIT:
	 char retStr[RETMAXSIZE];
	 HWND hwndCallback;
	 MCIERROR mcierr;
	PPCODE:
		mcierr = mciSendString(lpstrCommand, retStr, sizeof(retStr), NULL);
		if (getres)		XPUSHs(sv_2mortal(newSVpv(retStr,0)));
		XPUSHs(sv_2mortal(newSViv(mcierr)));


MCIERROR
mciSendCommand(mciId, uMsg, dwParam1, dwParam2)
	MCIDEVICEID mciId
	UINT uMsg
	DWORD dwParam1
	DWORD dwParam2


MCIDEVICEID
mciGetDeviceID(pszDevice)
	char* pszDevice


void
mciGetErrorString(mcierr)
	 MCIERROR mcierr
	PREINIT:
	 char szText[RETMAXSIZE];
	 UINT cchText;
	 BOOL ret;
	PPCODE:
		ret	= mciGetErrorString(mcierr, szText, sizeof(szText));
		XPUSHs(sv_2mortal(newSVpv(szText,0)));


#long
#mciGetCreatorTask(mciId)
#	MCIDEVICEID mciId
#
#
#int
#mciSetYieldProc(mciId, fpYieldProc, DWORD)
#	MCIDEVICEID mciId
#	long & fpYieldProc
#	DWORD dwYieldData
#
#
#long
#mciGetYieldProc(mciId, pdwYieldData)
#	MCIDEVICEID mciId
#	long & pdwYieldData

