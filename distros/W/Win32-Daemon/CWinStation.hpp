//////////////////////////////////////////////////////////////////////////////
//
//  CWinStation.hpp
//  Win32::Daemon Perl extension windows station class header file
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

#ifndef _CWINSTATION_H_
#define _CWINSTATION_H_

#define WINSTA_ALL  ( WINSTA_ACCESSCLIPBOARD        \
                    | WINSTA_CREATEDESKTOP          \
                    | WINSTA_ACCESSGLOBALATOMS      \
                    | WINSTA_ENUMDESKTOPS           \
                    | WINSTA_ENUMERATE              \
                    | WINSTA_EXITWINDOWS            \
                    | WINSTA_READATTRIBUTES         \
                    | WINSTA_READSCREEN             \
                    | WINSTA_WRITEATTRIBUTES        \
                    | DELETE                        \
                    | READ_CONTROL                  \
                    | WRITE_DAC                     \
                    | WRITE_OWNER )         

#define DESKTOP_ALL ( DESKTOP_CREATEMENU            \
                    | DESKTOP_CREATEWINDOW          \
                    | DESKTOP_ENUMERATE             \
                    | DESKTOP_HOOKCONTROL           \
                    | DESKTOP_JOURNALPLAYBACK       \
                    | DESKTOP_JOURNALRECORD         \
                    | DESKTOP_READOBJECTS           \
                    | DESKTOP_SWITCHDESKTOP         \
                    | DESKTOP_WRITEOBJECTS          \
                    | DELETE                        \
                    | READ_CONTROL                  \
                    | WRITE_DAC                     \
                    | WRITE_OWNER )

#define GENERIC_ACCESS ( GENERIC_READ               \
                        | GENERIC_WRITE             \
                        | GENERIC_EXECUTE           \
                        | GENERIC_ALL )


class CWinStation
{
public:
    CWinStation();
    ~CWinStation();
    BOOL Set( LPCTSTR pszWindowStation, LPCTSTR pszDesktop );
    BOOL Restore();
    SID *SetSid( SID *pSid );

private:
    enum PermissionType { eWindowStation, eDesktop };
    void GetThisStation();
    BOOL AddSecurityPrivileges( HANDLE hHandle, SID *pSid, PermissionType ePermType );

    HWINSTA m_hWinStation;
    DWORD   m_dwThreadId;
    HDESK   m_hDesktop;
    SID    *m_pSid;

};

#endif // _CWINSTATION_H_
