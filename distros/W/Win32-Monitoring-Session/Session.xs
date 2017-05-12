/* 
 * Win32::Monitoring::Session - 
 *    Access to information about sessions runnning on the host
 *
 * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
 * 
 * Win32::Monitoring::Session is free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.
 *
 * $Id: Session.xs 127 2008-08-13 09:09:45Z rplessl $ 
 */

#define __MSVCRT_VERSION__ 0x601
#define WINVER 0x0500
#include <windows.h>
#include <ntsecapi.h>
#include <string.h>
#define STATUS_SUCCESS    ((NTSTATUS) 0x00000000L)


#include "EXTERN.h"
#include "perl.h"  
#include "XSUB.h"  
#include "ppport.h"

#define hvs(KEY,VAL) hv_store_ent(hash, sv_2mortal(newSVpv(KEY,0)),VAL,0)

#define filetime2unixtime(ft) (long)((ft - 116444736000000000)/10000000)

#define Wide2MultiByteString(WideString,MBString) \
    if (WideString != NULL) { \
       int  stringLen = WideCharToMultiByte(CP_ACP, 0, WideString, -1, MBString, 0, NULL, NULL); \
       if(stringLen) { \
          MBString = (LPSTR) malloc(stringLen); \
          if(!WideCharToMultiByte(CP_ACP, 0, WideString, -1, MBString, stringLen, NULL, NULL)) { \
              MBString[0]='\0'; \
          } \
       }\
   }

#define ExtractSessionData(ENTRY) \
    if ((sessionData->ENTRY).Buffer != NULL) \
    { \
        usBuffer = (sessionData->ENTRY).Buffer; \
        usLength = (sessionData->ENTRY).Length; \
        if (usLength < (long)256) { \
            char* MBString = NULL; \
            wcsncpy_s(buffer, 256, usBuffer, usLength); \
            wcscat_s(buffer, 256, L""); \
            Wide2MultiByteString(usBuffer,MBString); \
            hvs(#ENTRY,newSVpv(MBString,0)); \
            if (MBString){ \
                free(MBString); \
            } \
        } \
    }





MODULE = Win32::Monitoring::Session		PACKAGE = Win32::Monitoring::Session

void
GetLogonSessionData(SessionId)
    DWORD SessionId
PREINIT:
    PSECURITY_LOGON_SESSION_DATA sessionData = NULL;
    LUID session;
    NTSTATUS ntstatus;
    WCHAR buffer[256];
    WCHAR *usBuffer;
    int usLength;
    HV *hash;
PPCODE:
    session.HighPart = 0;
    session.LowPart = SessionId;
    hash = newHV();
    ntstatus = LsaGetLogonSessionData (&session, &sessionData);
    if (ntstatus != STATUS_SUCCESS) {
        hvs("ERRCODE",newSViv(1));
        hvs("ERROR",newSVpv("Faild to get session data.",0));
        goto fn_done;
    }
    if (!sessionData) {
        hvs("ERRCODE",newSViv(2));
        hvs("ERROR",newSVpv("No session data found.",0));
        goto fn_done;
    }
    ExtractSessionData(UserName);
    ExtractSessionData(AuthenticationPackage);
    ExtractSessionData(LogonDomain);
    hvs("LogonTime",newSViv( filetime2unixtime(sessionData->LogonTime.QuadPart)) );
  fn_done:
    if (sessionData) {
        LsaFreeReturnBuffer(sessionData);    
    }
    EXTEND(sp,1);
    PUSHs(newRV_noinc((SV*)hash));
