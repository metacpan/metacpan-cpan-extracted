#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

use constant CLASS => 'XT::Files';

note('excludes');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is_deeply( $obj->{_excludes}, [], '_excludes is initialized to an empty array ref' );

is( $obj->exclude('hello'), undef, 'exclude returns undef' );
is_deeply( $obj->{_excludes}, ['hello'], '_excludes now contains one entry' );

is( $obj->exclude(qr{\Qhello world\E$}), undef, 'exclude returns undef' );
is_deeply( $obj->{_excludes}, [ 'hello', qr{\Qhello world\E$} ], '_excludes now contains two entry' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
