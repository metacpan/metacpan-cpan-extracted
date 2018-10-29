#!/usr/bin/perl

# Load testing for prefork.pm

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 19;

use prefork ();
ok( ! $prefork::FORKING, '$FORKING is false' );

# Prepare the things we need
my $notify1 = 0;
my $notify2 = 0;
sub _notify1 { $notify1++ }
sub _notify2 { $notify2++ }

# Start with some bad notify calls
eval { prefork::notify(undef) };
ok( $@, 'prefork::notify(undef) dies' );
ok( $@ =~ /prefork::notify was not passed a CODE reference/, 'die message matches expected' );
eval { prefork::notify('foo') };
ok( $@, 'prefork::notify("foo") dies' );
ok( $@ =~ /prefork::notify was not passed a CODE reference/, 'die message matches expected' );
eval { prefork::notify(\"foo") };
ok( $@, 'prefork::notify(\"foo") dies' );
ok( $@ =~ /prefork::notify was not passed a CODE reference/, 'die message matches expected' );

# Give notify the valid function ref
ok( prefork::notify( \&_notify1 ), 'prefork::notify(\&func) returns true' );
is( $notify1, 0, 'prefork::notify in non-FORKING context does not call callback' );
eval { prefork::notify(\&_notify1) };
ok( $@, 'Duplicate prefork::notify(\&func) call dies' );
ok( $@ =~ /Callback function already registered/, 'die message matches expected' );

# Call ->enable and see if the callback is called
ok( prefork::enable(), 'prefork::enable returns true' );
is( $notify1, 1, 'Callback appears to be executed correctly' );
ok( prefork::enable(), 'prefork::enable returns true' );
is( $notify1, 1, 'Callback is not called again' );

# Pass the second callback, which should be called immediately
ok( prefork::notify( \&_notify2 ), 'prefork::notify(\&func2) returns true' );
is( $notify2, 1, 'prefork::notify in FORKING context does call callback' );
ok( prefork::notify( \&_notify2 ), 'prefork::notify(\&func2) returns true' );
is( $notify2, 2, 'prefork::notify in FORKING context calls callback again' );
