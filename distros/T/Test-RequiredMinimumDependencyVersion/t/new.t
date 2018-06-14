#!perl

use 5.006;
use strict;
use warnings;

use version;

use Test::Fatal;
use Test::More 0.88;

use Test::RequiredMinimumDependencyVersion;

main();

sub main {

    my $class = 'Test::RequiredMinimumDependencyVersion';

    {
        my $obj = $class->new( module => { 'XYZ' => '0.001' } );
        isa_ok( $obj, $class, "new() returns a $class object" );

        ok( exists $obj->{_module}, '_module attribute exists' );
        is( ref $obj->{_module}, ref {}, '... and is initialized to a hash ref' );
        is_deeply( $obj->{_module}, { 'XYZ' => version->parse('0.001') }, '... which contains the requirements' );

        like( exception { $class->new() }, qr{No modules specified}, 'new() throws an exception if no modules are specified' );

        like( exception { $class->new( module => 47 ) }, qr{No modules specified}, 'new() throws an exception if modules are not specified in a hash ref' );

        like( exception { $class->new( module => { 'XYZ' => 'XLVII' } ) }, qr{Cannot parse version 'XLVII'}, 'new() throws an exception if the version cannot be parsed' );
    }

    # multiple modules
    {
        my $obj = $class->new( module => { 'XYZ' => '0.001', 'ABC' => 'v1', 'Hello::World' => '1.3' } );
        isa_ok( $obj, $class, "new() returns a $class object" );

        ok( exists $obj->{_module}, '_module attribute exists' );
        is( ref $obj->{_module}, ref {}, '... and is initialized to a hash ref' );
        is_deeply(
            $obj->{_module},
            {
                'XYZ'          => version->parse('0.001'),
                'ABC'          => version->parse('v1'),
                'Hello::World' => version->parse('1.3'),
            },
            '... which contains the requirements',
        );
    }

    #
    {
        like( exception { $class->new( 1, 2, 3 ) }, qr{Odd number of arguments}, 'throws an exception on even number of arguments' );

        like( exception { $class->new( module => { 'XYZ' => '0.001' }, no_such_argument => 12 ) }, qr{new[(][)] knows nothing about argument 'no_such_argument'}, 'throws an exception on unknown argument' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
