#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

use constant CLASS => 'XT::Files';

note('test_file(FILE)');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->file('hello'), undef, 'file hello does not exist' );

is( $obj->test_file('hello'), undef, 'test_file(hello) returns undef' );

my $file = $obj->file('hello');

isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );
is( $file->name, 'hello', q{name is 'hello'} );
ok( !$file->is_module, 'is_module is false' );
ok( !$file->is_pod,    'is_pod is false' );
ok( $file->is_script,  'is_script is true' );
ok( $file->is_test,    'is_test is true' );

note('test_file(FILE, DIR)');

$obj = CLASS()->new( -config => undef );

is( $obj->file('hello'), undef, 'file hello does not exist' );

is( $obj->test_file( 'hello', 't' ), undef, 'test_file(hello) returns undef' );

$file = $obj->file('hello');

isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );
is( $file->name, 'hello', q{name is 'hello'} );
ok( !$file->is_module, 'is_module is false' );
ok( !$file->is_pod,    'is_pod is false' );
ok( $file->is_script,  'is_script is true' );
ok( $file->is_test,    'is_test is true' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
