#!perl
# checks that fetch can fail

use strict;
use warnings;

use WWW::xkcd;
use Test::More tests => 7;
use Test::Fatal;

{
    no warnings qw/redefine once/;

    *WWW::xkcd::fetch_metadata = sub {
        my $self  = shift;
        my $comic = shift;

        isa_ok( $self, 'WWW::xkcd' );
        cmp_ok( $comic, '==', 100, 'Correct comic' );

        # this is purposely missing 'success' key
        return { img => 'myimage' };
    };

    *HTTP::Tiny::get = sub {
        my $self = shift;
        my $img  = shift;

        isa_ok( $self, 'HTTP::Tiny' );
        is( $img, 'myimage', 'Correct img' );

        # this is purposely missing 'success' key
        return { reason => 'bwahaha' };
    };
}

my $x = WWW::xkcd->new();
isa_ok( $x, 'WWW::xkcd' );
can_ok( $x, 'fetch'     );

like(
    exception { $x->fetch(100) },
    qr/^\QCan't fetch myimage\E/,
    'Failed with good reason',
);

