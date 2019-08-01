#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

use constant CLASS => 'XT::Files';

note('new');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );
isa_ok( $obj, CLASS(), 'new returned object' );

is( CLASS()->_is_initialized, undef, '... does not initialize the singleton' );

is_deeply( $obj->{_file}, {},     '... _file is an empty hash ref' );
is_deeply( $obj->{_excludes}, [], '... _excludes is an empty array ref' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
