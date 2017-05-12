#!/usr/bin/env perl -w

use strict;
use warnings;
use ex::lib '../lib';
use Test::More tests => 35+1;
use Test::NoWarnings;
our $COMPILE;
BEGIN { $COMPILE = 1; }

BEGIN {
    # define a sub at compiletime, like use base or export
    # so it also could be invoked in use self::init ...
    *x = sub {
        ok 1, 'x';
        ok $COMPILE, 'x at compile time';
        is shift(), __PACKAGE__, 'x as method';
        is_deeply(\@_,[qw(y z)], 'x args');
    }
}
    #self::init
use self::init
    \-x => qw( y z ),
;

use self::init
    [ x => qw( y z ) ],
;

BEGIN {
    eval {
        self::init->import(
            \-y => (),
        );
    };
    # diag $@;
    like ($@, qr/Can\'t locate object method "y" via package "main"/, 'no y at compile') or diag $@;

    eval {
        self::init->import(
            [ y => () ],
        );
    };
    # diag $@;
    like ($@, qr/Can\'t locate object method "y" via package "main"/, 'no y at compile 2') or diag $@;
}

ok defined &self::init, 'self::init';

self::init
    \-a => qw(a b),
    \-b => (),
    \-c => qw( c c ),
;

self::init
    [ a => qw(a b) ],
    [ b => () ],
    [ c => qw( c c ) ],
;

sub y {
    fail "shouldn't be called";
}

sub a {
    ok 1, 'a';
    ok !$COMPILE, 'a not at compile time';
    is shift(), __PACKAGE__, 'a as method';
    is_deeply(\@_,[qw(a b)], 'a args');
}

sub b {
    ok 1, 'b';
    ok !$COMPILE, 'b not at compile time';
    is shift(), __PACKAGE__, 'b as method';
    is_deeply(\@_,[], 'b args');
}

sub c {
    ok 1, 'c';
    ok !$COMPILE, 'c not at compile time';
    is shift(), __PACKAGE__, 'c as method';
    is_deeply(\@_,[qw(c c)], 'c args');
}

BEGIN {
    $COMPILE = 0;
}
