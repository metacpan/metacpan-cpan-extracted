#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 500_ping_icmp.t

# Test to perform icmp protocol testing.
# Root access is required.

use strict;
use warnings;

use Test::More tests => 2;
use Test::Ping;

use English '-no_match_vars';

sub IsAdminUser {
  return unless $OSNAME eq 'MSWin32' || $OSNAME eq 'cygwin';
  return unless eval { require Win32 };
  return unless defined &Win32::IsAdminUser;
  return Win32::IsAdminUser();
}

sub tests_write {
    return `write sys\$output f\$privilege("SYSPRV")` =~ m/FALSE/;
}

SKIP: {
    eval 'require Socket' || skip 'No socket', 2;

    if (
        ( $EUID and $OSNAME ne 'VMS' ) or
        ( ( $OSNAME eq 'MSWin32' or $OSNAME eq 'cygwin' )
            and !IsAdminUser() ) or
        ( $OSNAME eq 'VMS' and test_write() ) ) {
            skip 'icmp ping requires root privileges', 2;
    } elsif ($OSNAME eq 'MacOS') {
        skip 'icmp protocol not supported', 2;
    } else {
        create_ping_object_ok( 'icmp', 'Create ping object' );
        ping_ok( '127.0.0.1', 'Pinging 127.0.0.1' );
    }
}

