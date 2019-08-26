#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );
my $obj = CLASS()->instance;
isa_ok( $obj, CLASS(), 'instance returned object' );

is( CLASS()->_is_initialized, 1, '... and initializes the singleton' );

my $obj2 = CLASS()->instance;
isa_ok( $obj2, CLASS(), 'instance returned object' );

is( $obj, $obj2, '... the same' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
