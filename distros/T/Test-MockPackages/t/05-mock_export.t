#!perl -T
use strict;
use warnings;

use Test::Tester;
use Test::Exception;
use Test::More;
use Test::MockPackages qw(mock);

subtest 'validation' => sub {
    throws_ok(
        sub {
            mock();
        },
        qr/\Qconfig must be a HASH/x,
        'must be HASH'
    );

    throws_ok(
        sub {
            mock( { 'Foo' => [], } );
        },
        qr/\Qvalue for Foo must be a HASH/x,
        'value must be HASH'
    );

    throws_ok(
        sub {
            mock( { 'Foo' => { 'sub' => {}, }, } );
        },
        qr/\Qvalue for Foo::sub must be an ARRAY/x,
        'sub value must be ARRAY'
    );

    throws_ok(
        sub {
            mock( { 'Foo' => { 'sub' => [ 1 ], }, } );
        },
        qr/\Qvalue for Foo::sub must be an even-sized ARRAY/x,
        'sub value must be even-sized ARRAY'
    );

    throws_ok(
        sub {
            mock( { 'Foo' => { 'sub' => [ 'never_called' => {}, ], }, } );
        },
        qr/\Qarguments must be an ARRAY for mock method never_called in Foo::sub/x,
        'arguments must be an ARRAY'
    );

    throws_ok(
        sub {
            mock( { 'Foo' => { 'sub' => [ 'bad_method' => [], ], }, } );
        },
        qr/\Qbad_method is not a capability of Test::MockPackages::Mock in Foo::sub/x,
        'bad method used'
    );
};

subtest 'mock' => sub {
    check_tests(
        sub {
            my $m = mock(
                {   Foo => {
                        my_sub    => [ never_called => [], ],
                        my_method => [
                            is_method => [],
                            expects   => [ qw(one two) ],
                            returns   => [ qw(three) ],
                        ],
                    },
                    Bar => {
                        my_sub => [
                            expects => [ qw(one) ],
                            returns => [ qw(two) ],
                        ],
                        my_method => [
                            is_method => [],
                            expects   => [ qw(one) ],
                            returns   => [ qw(two) ],
                            expects   => [ qw(three four) ],
                            returns   => [ qw(four five) ],
                        ],
                    },
                }
            );

            is( Foo->my_method( 'one', 'two' ), 'three', 'three returned' );
            is( Bar::my_sub( 'bad' ),    'three', 'three returned for Bar::my_sub' );    # this will fail
            is( Bar->my_method( 'one' ), 'two',   'two returned' );
            is_deeply( [ Bar->my_method( 'three', 'four' ) ], [ 'four', 'five' ], 'list returned' );
        },
        [   {   ok    => 1,
                name  => 'Foo::my_method expects is correct',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'three returned',
                depth => undef,
            },
            {   ok    => 0,
                name  => 'Bar::my_sub expects is correct',
                depth => undef,
            },
            {   ok    => 0,
                name  => 'three returned for Bar::my_sub',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Bar::my_method expects is correct',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'two returned',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Bar::my_method expects is correct',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'list returned',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Bar::my_method called 2 times',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Bar::my_sub called 1 time',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Foo::my_method called 1 time',
                depth => undef,
            },
            {   ok    => 1,
                name  => 'Foo::my_sub called 0 times',
                depth => undef,
            },
        ],
        'mock'
    );
};

done_testing();
