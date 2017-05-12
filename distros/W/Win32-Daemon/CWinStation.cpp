//////////////////////////////////////////////////////////////////////////////
//
//  CWinStation.cpp
//  Win32::Daemon Perl extension windows station class source file
//
//  Copyright (c) 1998-2008 Dave Roth
//  Courtesy of Roth Consulting
//  http://www.roth.net/
//
//  This file may be copied or modified only under the terms of either 
//  the Artistic License or the GNU General Public License, which may 
//  be found in the Perl 5.0 source kit.
//
//  2008.03.24  :Date
//  20080324    :Version
//////////////////////////////////////////////////////////////////////////////

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tchar.h>
#include <stdio.h>

#include "constant.h"
#include "CWinStation.hpp"

////////////////////////////////////////////////////////////////////////////
CWinStation::CWinStation()
{
    m_hWinStation = NULL;
    m_hDesktop = NULL;
    m_pSid = NULL;
    GetThisStation();
}

////////////////////////////////////////////////////////////////////////////
CWinStation::~CWinStation()
{
}

////////////////////////////////////////////////////////////////////////////
SID *CWinStation::SetSid( SID *pSid )
{
    m_pSid = pSid;
    return( m_pSid );
}


////////////////////////////////////////////////////////////////////////////
void CWinStation::GetThisStation()
{
    // Call GetDesktopWindow() so that a window station and
    // is associated with the service.  THis only is a problem with pre-NT 4.0
    HWND hDesktopWnd = GetDesktopWindow(); 
//    _ASSERT( hDesktopWnd );

    m_hWinStation   = GetProcessWindowStation(); 
    m_hDesktop      = GetThreadDesktop( GetCurrentThreadId() ); 
}

////////////////////////////////////////////////////////////////////////////
BOOL CWinStation::Set( LPCTSTR pszWindowStation, LPCTSTR pszDesktop )
{
    BOOL fResult = FALSE;
    HWINSTA hWinStation = NULL;
    HWINSTA hWinStationBackup = GetProcessWindowStation();
    DWORD dwPerms = MAXIMUM_ALLOWED 
                    | WINSTA_ACCESSCLIPBOARD 
                    | WINSTA_EXITWINDOWS
                    | READ_CONTROL
                    | WRITE_DAC; 
//                    | WINSTA_READATTRIBUTES 
//                    | WINSTA_READSCREEN; 
//                    | WINSTA_WRITEATTRIBUTES;

#ifdef _DEBUG
    TCHAR ALERT_BUFFER[ 1024 ];
#endif
        
    ALERT( "CWinStation::Set: Opening the Windows Station...\n" );
    hWinStation = OpenWindowStation( (LPTSTR) pszWindowStation, TRUE, dwPerms ); 
    if( NULL != hWinStation )  
    { 
        ALERT( "CWinStation::Set: Adding the SID to the WinStation...\n" );
        if( AddSecurityPrivileges( (HANDLE) hWinStation, m_pSid, eWindowStation ) )
        {
            ALERT( "CWinStation::Set: Added the SID to the WinStation\n" );
        }

        if( SetProcessWindowStation( hWinStation ) )
        {
            HDESK hDesktopBackup = GetThreadDesktop( GetCurrentThreadId() );
            //  Get the new desktop: specify inheritance by new processes and max permissions
            DWORD dwPerms = MAXIMUM_ALLOWED 
                            | DESKTOP_SWITCHDESKTOP 
                            | DESKTOP_READOBJECTS
                            | DESKTOP_WRITEOBJECTS 
                            | DESKTOP_CREATEWINDOW
                            | READ_CONTROL
                            | WRITE_DAC;
            HDESK hDesktop = OpenDesktop( (LPTSTR) pszDesktop, 0, TRUE, dwPerms );
            if( NULL != hDesktop )
            {
                    fResult = TRUE;

                    TCHAR szBuffer[ 2048 ];
                    TCHAR szBuffer2[ 4096];
                    TextFromSid( szBuffer, (SID*) m_pSid );
                    wsprintf( szBuffer2, TEXT( "CWinStation::Set: Got the process' SID: %s\n" ), szBuffer );
                    ALERT( szBuffer2 );

                if( AddSecurityPrivileges( (HANDLE) hDesktop, m_pSid, eDesktop ) )
                {
                    ALERT( "CWinStation::Set: Added the SID to the Desktop\n" );
                    fResult = SetThreadDesktop( hDesktop );
                }
            
                
                if( TRUE == fResult )
                {
                    ALERT( "CWinStation::Set: Successfully set the desktop window & desktop" );
                }
                else
                {
                    SetProcessWindowStation( hWinStationBackup );
                    SetThreadDesktop( hDesktopBackup );
                }
            }
#ifdef _DEBUG
    else
    {
        wsprintf( ALERT_BUFFER, TEXT( "CWinStation::Set: ERROR: 0x%08x\n" ), GetLastError() );
        ALERT( ALERT_BUFFER );
    }
#endif

            CloseDesktop( hDesktop );
        }
#ifdef _DEBUG
    else
    {
        wsprintf( ALERT_BUFFER, TEXT( "CWinStation::Set: ERROR: 0x%08x\n" ), GetLastError() );
        ALERT( ALERT_BUFFER );
    }
#endif

        CloseWindowStation( hWinStation );    
    }
#ifdef _DEBUG
    else
    {
        wsprintf( ALERT_BUFFER, TEXT( "CWinStation::Set: ERROR: 0x%08x\n" ), GetLastError() );
        ALERT( ALERT_BUFFER );
    }
#endif

    return( fResult );
}

////////////////////////////////////////////////////////////////////////////
BOOL CWinStation::Restore()
{
    BOOL fResult = FALSE;

    if( FALSE != SetProcessWindowStation( m_hWinStation ) )
    {
        if( FALSE != SetThreadDesktop( m_hDesktop ) )
        {
            fResult = TRUE;
        }
    }
    return( fResult );
}

////////////////////////////////////////////////////////////////////////////
BOOL CWinStation::AddSecurityPrivileges( HANDLE hHandle, SID *pSid, PermissionType PermType )
{
    SECURITY_INFORMATION securityInfo;
    PSECURITY_DESCRIPTOR pSd = NULL;
    PSECURITY_DESCRIPTOR pNewSd = NULL;
    DWORD dwLength = 0;
    DWORD dwError;
    BOOL bResult = FALSE;
    BOOL bTempResult = FALSE;

#ifdef _DEBUG
    TCHAR szDebugText[ 1024 ];
    TextFromSid( szDebugText, (SID*) pSid );
#endif

    securityInfo = DACL_SECURITY_INFORMATION;

    // Fake out a call to fetch the security descriptor from the
    // desktop object. Note that the size of the security descriptor
    // object is 0 bytes long. this will cause the function to
    // return false and populate dwLength with the # of bytes
    // required to hold the security descriptor.
    bTempResult = GetUserObjectSecurity( 
                            hHandle,
                            &securityInfo,
                            pSd,
                            0,
                            &dwLength );
    dwError = GetLastError();
    if( ( FALSE == bTempResult ) && ( ERROR_INSUFFICIENT_BUFFER == dwError ) )
    {
        // alloc memory for the security desc.
        pSd = (PSECURITY_DESCRIPTOR)new BYTE [ dwLength ];
        pNewSd = (PSECURITY_DESCRIPTOR)new BYTE [ dwLength ];
        if( ( NULL != pSd ) && ( NULL != pNewSd ) )
        {
            DWORD dwSdLength;
            
            InitializeSecurityDescriptor(
                  pSd,
                  SECURITY_DESCRIPTOR_REVISION
            );

            InitializeSecurityDescriptor(
                  pNewSd,
                  SECURITY_DESCRIPTOR_REVISION
            );
                  
            // Fetch the security descriptor from the
            // desktop object
            bTempResult = GetUserObjectSecurity( 
                                hHandle,
                                &securityInfo,
                                pSd,
                                dwLength,
                                &dwSdLength );
            if( ( FALSE != bTempResult ) && ( IsValidSecurityDescriptor( pSd ) ) )
            {
                BOOL bDaclPresent = FALSE;
                BOOL bDaclDefaulted = FALSE;
                PACL pDacl = NULL;
                PACL pNewDacl = NULL;
                       
                // Fetch the DACL from the security descriptor
                bTempResult = GetSecurityDescriptorDacl( 
                                                pSd,
                                                &bDaclPresent,
                                                &pDacl,
                                                &bDaclDefaulted );
                if( ( FALSE != bTempResult ) && ( FALSE != bDaclPresent ) )
                {
                    ACL_SIZE_INFORMATION AclSizeInfo;
                    PACL pNewDacl = NULL;
                    ACCESS_ALLOWED_ACE *pAce = NULL;


                    // We should check to see of bDaclDefaulted is
                    // FALSE (meanign that the DACL was specified by
                    // some process; TRUE means that the Dacl was
                    // obtained by some default process--nothing specified
                    // a Dacl specifically).
                    ZeroMemory( &AclSizeInfo, sizeof( AclSizeInfo ) );
                    AclSizeInfo.AclBytesInUse = sizeof( ACL );

                    if( GetAclInformation(
                           pDacl,
                           (LPVOID) &AclSizeInfo,
                           sizeof( ACL_SIZE_INFORMATION ),
                           AclSizeInformation
                        ) )
                    {
                        DWORD dwNewAclSize = AclSizeInfo.AclBytesInUse 
                                                + ( 2 *
                                                sizeof( ACCESS_ALLOWED_ACE ) ) 
                                                + ( 2 * GetLengthSid( pSid ) ) 
                                                - ( 2 * sizeof( DWORD ) );

                         //
                         // allocate memory for the new acl
                         //
                         pNewDacl = (PACL) new BYTE [ dwNewAclSize ];
                         if( NULL != pNewDacl )
                         {
                             ZeroMemory( pNewDacl, dwNewAclSize );
                             InitializeAcl( pNewDacl, dwNewAclSize, ACL_REVISION );
                         }
                    }

                    // copy the ACEs to our new ACL
                    if( 0 != AclSizeInfo.AceCount )
                    {
ALERT( "[CWinStation::AddSecurityPrivileges] Populating new DACL.\n" );
                        for( DWORD dwIndex = 0; dwIndex < AclSizeInfo.AceCount; dwIndex++ )
                        {
                            // get an ACE
                            if( GetAce( pDacl, dwIndex, (PVOID*) &pAce ) )
                            {
                                
#ifdef _DEBUG
    TCHAR szSid[ 256 ];
    SID *pSid = (SID*) pAce->SidStart;
    _tcscpy( szSid, TEXT( "" ) );
    TextFromSid( szSid, pSid );
    wsprintf( szDebugText, 
              TEXT( "[CWinStation::AddSecurityPrivileges] Found ACE:\n\t\tType: 0x%04x Flags: 0x%04x Mask: 0x%08x\n\t\tSid: %s\n" ),
              pAce->Header.AceType,
              pAce->Header.AceFlags,
              pAce->Mask,
              szSid
              );
    ALERT( szDebugText );
#endif
                                if( AddAce(
                                            pNewDacl,
                                            ACL_REVISION,
                                            MAXDWORD,
                                            (LPVOID) pAce,
                                            pAce->Header.AceSize ) )
                                {
                                    ALERT( "[CWinStation::AddSecurityPrivileges] Added ACE." );
                                }
                            }
                        }
                    }

                    pAce = (ACCESS_ALLOWED_ACE *) new BYTE [ sizeof( ACCESS_ALLOWED_ACE ) 
                                                             + GetLengthSid( pSid ) 
                                                             - sizeof( DWORD ) ];
                    if( NULL != pAce )
                    {
                        switch( PermType )
                        {
                        case eWindowStation:
                            // Add two ACE's to the WindowStation
                            pAce->Header.AceType  = ACCESS_ALLOWED_ACE_TYPE;
                            pAce->Header.AceFlags = CONTAINER_INHERIT_ACE 
                                                    | INHERIT_ONLY_ACE      
                                                    | OBJECT_INHERIT_ACE;
                            pAce->Header.AceSize  = (WORD) ( sizeof( ACCESS_ALLOWED_ACE ) 
                                                    + GetLengthSid( pSid ) 
                                                    - sizeof( DWORD ) );
                            pAce->Mask = GENERIC_ACCESS;


                            CopySid( GetLengthSid( pSid), &pAce->SidStart, pSid );
                            if( AddAce(
                                        pNewDacl,
                                        ACL_REVISION,
                                        MAXDWORD,
                                        (LPVOID) pAce,
                                        pAce->Header.AceSize ) )
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Added new windowstation ACE 1.\n" );
                            }
    #ifdef _DEBUG
                            else
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Failed to add new windowstation ACE 1.\n" );
                            }
    #endif
                            //
                            // add the second ACE to the windowstation
                            //
                            pAce->Header.AceFlags = NO_PROPAGATE_INHERIT_ACE;
                            pAce->Mask = WINSTA_ALL;
                            if( AddAce(
                                        pNewDacl,
                                        ACL_REVISION,
                                        MAXDWORD,
                                        (LPVOID) pAce,
                                        pAce->Header.AceSize ) )
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Added new windowstation ACE 2.\n" );
                            }
#ifdef _DEBUG
                            else
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Failed to add new windowstation ACE 2.\n" );
                            }
#endif
                            break;

                        case eDesktop:
                            // Add an access allowed ACE to the desktop
                            if( AddAccessAllowedAce(
                                        pNewDacl,
                                        ACL_REVISION,
                                        DESKTOP_ALL,
                                        pSid
                                        ) )
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Added new desktop ACE 2.\n" );
                            }
#ifdef _DEBUG
                            else
                            {
                                ALERT( "[CWinStation::AddSecurityPrivileges] Failed to add new desktop ACE 2.\n" );
                            }
#endif
                            break;
                        }
                    }
                    delete [] pAce;
                    
                    // Update the Security Descriptor with the new
                    // DACL
                    if( TRUE == SetSecurityDescriptorDacl( 
                                                pNewSd,
                                                TRUE,
                                                pNewDacl,
                                                FALSE ) )
                    {
                        // Go ahead and set the updated Security
                        // Descriptor on the desktop object
                        bResult = SetUserObjectSecurity(
                                                hHandle,
                                                &securityInfo,
                                                pNewSd );
                    }
                    else
                    {
                        dwError = GetLastError();
                    }

                    if( NULL != pNewDacl )
                    {
                        delete [] pNewDacl;
                    }
                }

            }
        }
    }
    delete [] (BYTE*)pSd;    
    delete [] (BYTE*)pNewSd;

    return( bResult );
}

