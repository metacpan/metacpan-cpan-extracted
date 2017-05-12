#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 510_ping_udp.t

# Test to perform udp protocol testing.

use strict;
use warnings;

use Test::More tests => 2;
use Test::Ping;

use English '-no_match_vars';

sub isWindowsVista {
   return unless $OSNAME eq 'MSWin32' or $OSNAME eq 'cygwin';
   return unless eval { require Win32 };
   return unless defined &Win32::GetOSName;
   return Win32::GetOSName() eq 'WinVista';
}

SKIP: {
    eval 'require Socket'          || skip 'No Socket',    2;
    getservbyname( 'echo', 'udp' ) || skip 'No echo port', 2;

    isWindowsVista() &&
        skip q{udp ping blocked by Vista's default settings}, 2;

    create_ping_object_ok( 'udp', 'Create ping object' );
    ping_ok( '127.0.0.1', 'Pinging 127.0.0.1' );
}

