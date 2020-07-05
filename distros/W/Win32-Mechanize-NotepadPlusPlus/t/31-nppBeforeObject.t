########################################################################
# Verifies previous launch of Notepad++, before object instantiation
#   (so need to launch if there aren't any existing Notepad++ executables)
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Encode qw'encode';

use FindBin;
use lib $FindBin::Bin;

use Win32::API;
use Win32::GuiTest 1.64 qw':FUNC !SendMessage';     # 1.64 required for 64-bit SendMessage

BEGIN {
    Win32::API::->Import("user32","DWORD GetWindowThreadProcessId( HWND hWnd, LPDWORD lpdwProcessId)") or die "GetWindowThreadProcessId: $^E";
    Win32::API::->Import("psapi","DWORD WINAPI GetModuleFileNameEx(HANDLE  hProcess, HMODULE hModule, LPTSTR  lpFilename, DWORD   nSize)") or die "GetModuleFileNameEx: $^E";
    Win32::API::->Import("psapi","BOOL EnumProcessModules(HANDLE  hProcess, HMODULE *lphModule, DWORD   cb, LPDWORD lpcbNeeded)") or die "EnumProcessModules: $^E";
}

# __ptrBytes and __ptrPack: use for setting number of bytes or the pack/unpack character for a perl-compatible pointer
sub __ptrBytes64 () { 8 }
sub __ptrPack64  () { 'Q' }
sub __ptrBytes32 () { 4 }
sub __ptrPack32  () { 'L' }

BEGIN {
    use Config;
    if( $Config{ptrsize}==8 ) {
        *__ptrBytes = \&__ptrBytes64;
        *__ptrPack  = \&__ptrPack64;
    } elsif ( $Config{ptrsize}==4) {
        *__ptrBytes = \&__ptrBytes32;
        *__ptrPack  = \&__ptrPack32;
    } else {
        die "unknown pointer size: $Config{ptrsize}bytes";
    }
}


note "Is it running to begin with...\n";
my($hwnd) = FindWindowLike(0,undef,'^Notepad\+\+$', undef, undef);
ok $hwnd||-1, 'npp already exists vs not running';
note "\n\t", sprintf "initial hwnd is %s\n", $hwnd//'<undef>';


note "find the exe name...\n";
my $file_exe = ($hwnd) ? _hwnd_to_path($hwnd) : _search_for_npp_exe();
note "... found ", $file_exe, "\n\n";
ok -x $file_exe, 'notepad++.exe executable found';

my $created;
if(!$hwnd) {
    note "want to create the process...\n";
    system(1, $file_exe);
    ($created) = WaitWindowLike(0,undef,'^Notepad\+\+$', undef, undef, 5);
}

note "verify it is running after intentional launch...\n";
my($rwnd) = FindWindowLike(0,undef,'^Notepad\+\+$', undef, undef);
note "\n\t", sprintf "rwnd = %s\n", $rwnd//'<undef>';
ok $rwnd, 'Notepad++ running after launch';

# instantiate a NotepadPlusPlus object, thus using the same object
require_ok( 'Win32::Mechanize::NotepadPlusPlus' );

# the objects should match
note "verify it matches...\n";
my $mwnd = Win32::Mechanize::NotepadPlusPlus::notepad()->hwnd();
note "\n\t", sprintf "mwnd = %s\n", $mwnd//'<undef>';
is $mwnd, $rwnd, 'verify the instance I intentionally ran matches the instance from the Notepad object';


SKIP: {
    skip "this test did not create the NPP process", 1 unless $created;

    # use the PID from the notepad object to kill the instance..., if this test created it
    my $pid = Win32::Mechanize::NotepadPlusPlus::notepad()->{_pid};
    note "\n\t", sprintf "pid = %s\n", $pid;

    kill -9, $pid;
    sleep(1);   # give the process time to die

    note "verify it's not running (assuming I created NPP process)...\n";
    my($kwnd) = FindWindowLike(0,undef,'^Notepad\+\+$', undef, undef);
    note "\t", sprintf "kwnd = %s\n", $kwnd//'<undef>';
    ok !defined($kwnd), 'Notepad++ not currently running';
}

done_testing;

sub _hwnd_to_path
{
    my $hwnd = shift;
    my $filename;

    # use a dummy vbuf for getting the hprocess
    my $vbuf = AllocateVirtualBuffer($hwnd, 1);
    my $hprocess = $vbuf->{process};

    my $LENGTH_MAX = 1024;
    my $ENCODING  = 'cp1252';
    my $cb = Win32::API::Type->sizeof( 'HMODULE' ) * $LENGTH_MAX;
    my $lphmodule  = "\x0" x $cb;
    my $lpcbneeded = "\x0" x $cb;

    if (EnumProcessModules($hprocess, $lphmodule, $cb, $lpcbneeded)) {
        # the first 8 bytes of lphmodule would be the first pointer...
        my $hmodule = unpack 'Q', substr($lphmodule,0,8);
        my $size = Win32::API::Type->sizeof( 'CHAR*' ) * $LENGTH_MAX;
        my $lpfilenameex = "\x0" x $size;
        GetModuleFileNameEx($hprocess, $hmodule, $lpfilenameex, $size);
        $filename = Encode::decode($ENCODING, unpack "Z*", $lpfilenameex);
    }
    FreeVirtualBuffer($vbuf);
    return $filename;
}

sub _search_for_npp_exe {
    my $npp_exe;
    use File::Which 'which';
    # priority to path, 64bit, default, then x86-specific locations
    my @try = ( which('notepad++') );
    push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
    push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
    push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
    foreach my $try ( @try )
    {
        $npp_exe = $try if -x $try;
        last if defined $npp_exe;
    }
    die "could not find an instance of notepad++; please add it to your path" unless defined $npp_exe;
    #print STDERR __PACKAGE__, " found '$npp_exe'\n";
    return $npp_exe;
}
