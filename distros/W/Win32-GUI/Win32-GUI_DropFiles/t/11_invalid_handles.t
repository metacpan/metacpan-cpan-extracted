#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 11_invalid_handles.t,v 1.1 2006/04/25 21:38:19 robertemay Exp $
#
# Test Win32::GUI::DropFiles win32 API doesn't barf with invalid handles

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI::DropFiles will load.

use Test::More;
use Win32::GUI::DropFiles;

my @handles = (0, int(rand(2**32)),);

plan tests => 6 * scalar @handles;

# Useful Constants:
sub EINVAL() {22}
sub ERROR_INVALID_HANDLE() {6}

# On cygwin, $^E == $! (no OS extended errors)
my $EXPECTED_E = ERROR_INVALID_HANDLE;
if(lc $^O eq "cygwin") {
    $EXPECTED_E = EINVAL;
}

for my $h (@handles) {
    my ($r, $e);

    # DragQueryFile
    $!=0;$^E=0;
    $r = Win32::GUI::DropFiles::DragQueryFile($h);
    $e = $^E;  # Record $^E immediately after call
    is($r , undef, "DragQueryFile: Invalid handle $h returns undef");
    SKIP: {
        skip "DragQueryFiles: Can't test error codes if we didn't get an error", 2 if defined $r;

        cmp_ok($!, "==", EINVAL, "DragQueryFile: Errno set to EINVAL");
        cmp_ok($e, "==", $EXPECTED_E, "DragQueryFile: LastError set to ERROR_INVALID_HANDLE");
    }

    # DragQueryPoint
    $!=0;$^E=0;
    $r = Win32::GUI::DropFiles::DragQueryPoint($h);
    $e = $^E;  # Record $^E immediately after call
    is($r, undef, "DragQueryPoint: Invalid handle $h returns undef");
    SKIP: {
        skip "DragQueryPoint: Can't test error codes if we didn't get an error", 2 if defined $r;

        cmp_ok($!, "==", EINVAL, "DragQueryPoint: Errno set to EINVAL");
        cmp_ok($e, "==", $EXPECTED_E, "DragQueryPoint: LastError set to ERROR_INVALID_HANDLE");
    }

    # DragFinish
    # DragFinish sets LastError inconsistently, using ERROR_INVALID_PARAMETER
    # on win98 and ERROR_INVALID_HANDLE on winNT.  Also on WinNT, doesn't
    # consider 0 to be invalid.   As there is no return value from DragFinish,
    # the user can't tell if there was an error or not, so doen't know if
    # $^E contains anything useful or not, so we don't need to do the test.
}
