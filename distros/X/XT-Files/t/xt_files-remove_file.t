#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

note('remove_file(FILE)');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->test_file('hello'), undef, 'test_file(hello) returns undef' );
my $file = $obj->file('hello');
isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );

is( $obj->remove_file('hello'), undef, 'remove_file(hello) returns undef' );
ok( !exists $obj->{_file}->{'hello'}, q{entry for file 'hello' no longer exists} );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
