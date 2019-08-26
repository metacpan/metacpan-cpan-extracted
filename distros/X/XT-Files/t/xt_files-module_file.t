#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

note('module_file(NAME)');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->file('hello'), undef, 'file hello does not exist' );

is( $obj->module_file('hello'), undef, 'module_file(hello) returns undef' );

my $file = $obj->file('hello');

isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );
is( $file->name, 'hello', q{name is 'hello'} );
ok( $file->is_module,  'is_module is true' );
ok( !$file->is_pod,    'is_pod is false' );
ok( !$file->is_script, 'is_script is false' );
ok( !$file->is_test,   'is_test is false' );

note('module_file(NAME, DIR)');

$obj = CLASS()->new( -config => undef );

is( $obj->file('hello'), undef, 'file hello does not exist' );

is( $obj->module_file( 'hello', 'lib' ), undef, 'module_file(hello) returns undef' );

$file = $obj->file('hello');

isa_ok( $file, 'XT::Files::File', 'file hello is now an obj of type XT::Files::File' );
is( $file->name, 'hello', q{name is 'hello'} );
ok( $file->is_module,  'is_module is true' );
ok( !$file->is_pod,    'is_pod is false' );
ok( !$file->is_script, 'is_script is false' );
ok( !$file->is_test,   'is_test is false' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
