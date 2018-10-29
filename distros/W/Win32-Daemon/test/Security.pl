#//////////////////////////////////////////////////////////////////////////////
#//
#//  Security.pl
#//  Win32::Daemon Perl extension test script demonstrating security ACL 
#//  support.
#//
#//  Copyright (c) 1998-2008 Dave Roth
#//  Courtesy of Roth Consulting
#//  http://www.roth.net/
#//
#//  This file may be copied or modified only under the terms of either 
#//  the Artistic License or the GNU General Public License, which may 
#//  be found in the Perl 5.0 source kit.
#//
#//  2008.03.24  :Date
#//  20080324    :Version
#//////////////////////////////////////////////////////////////////////////////


use Win32::Daemon;
use Win32::Perms;

$Machine = "proxy";
$ServiceName = "ProcMon";
$Account = "ROTH\\DaemonCRON";

# Enough permissions for the account to control the service 
# but not modify it. It can start, stop, pause and resume.
$Mask = READ_CONTROL
        | FILE_READ_EA
        | FILE_WRITE_EA
        | FILE_READ_ATTRIBUTES
        | FILE_WRITE_ATTRIBUTES;

$SD = Win32::Daemon::GetSecurity( $Machine, $ServiceName ) || die;
if( $Perm = new Win32::Perms )
{
    $Perm->Import( $SD );
    $Perm->Dump();
    $Perm->Add( $Account, $Mask, ALLOW, 0 );
    $NewSD = $Perm->GetSD( SD_RELATIVE );
    if( Win32::Daemon::SetSecurity( $Machine, $ServiceName, $Perm ) )
    {
        print "Successfully applied.\n";
        $Perm->Remove( -1 );
        $SD = Win32::Daemon::GetSecurity( $Machine, $ServiceName ) || die;
        $Perm->Import( $SD );
        $Perm->Dump;
    }
}