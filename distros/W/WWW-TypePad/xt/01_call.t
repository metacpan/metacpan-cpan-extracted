use strict;
use Test::More tests => 5;

use WWW::TypePad;

my $tp = WWW::TypePad->new;
my $faved = $tp->call( GET => '/assets/6a00d83455876069e20120a72c0fea970b/favorites.json' );
isa_ok $faved, 'HASH';
ok $faved->{entries}, 'faves response has entries key';

my $obj;
eval {
    $obj = $tp->call( GET => '/foo/bar.json' );
};
my $E = $@;
isa_ok $E, 'WWW::TypePad::Error::HTTP';
is $E->code, 404, 'response code is 404';
ok !defined $obj, 'response to tp->call is undef';