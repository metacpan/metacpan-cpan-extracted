#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

note('ignore_file(FILE)');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->pod_file('hello'), undef, 'pod_file(hello) returns undef' );
my $file = $obj->file('hello');
isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );

is( $obj->ignore_file('hello'), undef, 'ignore_file(hello) returns undef' );
ok( exists $obj->{_file}->{'hello'}, q{entry for file 'hello' still exists} );
is( $obj->{_file}->{'hello'}, undef, '... undef' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
