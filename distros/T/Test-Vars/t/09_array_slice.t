#!perl -w

use strict;
use Test::More;

unless ( eval "require Moose::Role; 1;" ) {
    plan skip_all => 'This test requires Moose::Role';
}

use File::Spec::Functions qw( catfile );
use Test::Vars;

{
    my $file = catfile( qw( t lib ArraySlice.pm ) );
    my @unused;
    my $handler = sub {
        push @unused, [@_];
    };
    local $@;
    eval { test_vars( $file, $handler ) };
    is( $@, q{}, 'no exception calling test_vars on t/lib/ArraySlice.pm' );
    is_deeply(
        \@unused,
        [
            [
                't/lib/ArraySlice.pm',
                0,
                [
                    [
                        'note',
                        'checking ArraySlice in ArraySlice.pm ...'
                    ],
                ]
            ]
        ],
        'got expected output from test_vars - no unused vars'
    );
}

done_testing;
