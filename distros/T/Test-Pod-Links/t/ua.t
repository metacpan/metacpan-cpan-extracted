#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Test::Pod::Links;

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::HTTP::NoUA;

main();

sub main {
    my $class = 'Test::Pod::Links';

    my $obj = $class->new();

    isa_ok( $obj->_ua(), 'HTTP::Tiny', q{_ua() returns an HTTP::Tiny object} );
    isa_ok( $obj->{_ua}, 'HTTP::Tiny', q{... and _ua attribute isa HTTP::Tiny object} );

    like( exception { $obj->_ua('hello world') }, q{/ua must have method 'head'/}, '_ua throws an exception if argument is not an object' );

    my $ua = bless {}, 'Local::NoUA';
    like( exception { $obj->_ua($ua) }, q{/ua must have method 'head'/}, q{... or does not have a method 'head'} );

    $ua = bless {}, 'Local::HTTP::NoUA';
    isa_ok( $obj->_ua($ua), 'Local::HTTP::NoUA', q{... and does not throw an exception if passed a 'ua' with a 'head' method} );

    isa_ok( $obj->_ua( bless( {}, 'HTTP::Tiny' ), 2, 3 ), 'HTTP::Tiny', '_ua silently ignores superfluous arguments' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
