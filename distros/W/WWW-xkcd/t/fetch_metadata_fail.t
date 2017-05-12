#!perl
# checks that fetch_metadata can fail

use strict;
use warnings;

use Test::More tests => 8;
use Test::Fatal;

# this makes the $can_async return false
{
    no warnings qw/redefine once/;

    sub Try::Tiny::try(&;@) {
        my $coderef = shift;

        is(
            ref $coderef,
            ref sub {1},
            'Got code reference when overriding try()',
        );

        return 0;
    }

    sub Try::Tiny::catch(&;@) {
        my $coderef = shift;

        is(
            ref $coderef,
            ref sub {1},
            'Got code reference when overriding catch()',
        );

        return 0;
    }

    require WWW::xkcd;
}

{
    no warnings qw/redefine once/;

    *HTTP::Tiny::get = sub {
        my $self = shift;
        my $img  = shift;

        isa_ok( $self, 'HTTP::Tiny' );
        is( $img, 'http://xkcd.com/100/info.0.json', 'Correct img' );

        # this is purposely missing 'success' key
        return { reason => 'bwahaha' };
    };
}

my $x = WWW::xkcd->new();
isa_ok( $x, 'WWW::xkcd'      );
can_ok( $x, 'fetch_metadata' );

like(
    exception { $x->fetch_metadata(100) },
    qr/bwahaha/,
    'Failed with good reason',
);

SKIP: {
    local $@ = undef;
    eval 'use AnyEvent';
    $@ and skip 'AnyEvent is needed for this test' => 1;

    like(
        exception { $x->fetch_metadata(100, sub {1} ) },
        qr/^\QAnyEvent and AnyEvent::HTTP are required for async mode\E/,
        'Failed in async as well',
    );
};
