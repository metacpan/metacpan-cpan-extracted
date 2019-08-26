#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use XT::Files::File;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files::File';

like( exception { CLASS()->new() }, q{/name attribute required/}, q{new throws an exception if 'name' argument is missing} );

{
    for my $name ( 'test 1 2 3', '0', q{} ) {
        my $obj = CLASS()->new( name => $name );
        isa_ok( $obj, CLASS(), 'new returned object' );

        is( $obj->{name}, $name, '... name is correctly set' );
        is( $obj->name(), $name, '... name accessor works' );
        is( "$obj",       $name, '... object stringifies to name' );
        ok( $obj, '... and is true' );
    }
}

{
    my $obj = CLASS()->new( { name => 'hello world' } );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->is_module, q{}, '... is_module returns empty string' );
    is( $obj->is_pod,    q{}, '... is_pod returns empty string' );
    is( $obj->is_script, q{}, '... is_script returns empty string' );
    is( $obj->is_test,   q{}, '... is_test returns empty string' );
}

{
    my $obj = CLASS()->new( { name => 'hello world', dir => 'lib' } );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->is_module, q{}, '... is_module returns empty string' );
    is( $obj->is_pod,    q{}, '... is_pod returns empty string' );
    is( $obj->is_script, q{}, '... is_script returns empty string' );
    is( $obj->is_test,   q{}, '... is_test returns empty string' );
}

{
    my $obj = CLASS()->new( { name => 'hello world', is_module => 1 } );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->is_module, 1,   '... is_module returns 1' );
    is( $obj->is_pod,    q{}, '... is_pod returns empty string' );
    is( $obj->is_script, q{}, '... is_script returns empty string' );
    is( $obj->is_test,   q{}, '... is_test returns empty string' );
}

{
    my $obj = CLASS()->new( name => 'hello world', is_module => 1, is_pod => 1, is_script => 1, is_test => 1 );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->is_module, 1, '... is_module returns 1' );
    is( $obj->is_pod,    1, '... is_pod returns 1' );
    is( $obj->is_script, 1, '... is_script returns 1' );
    is( $obj->is_test,   1, '... is_test returns 1' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
