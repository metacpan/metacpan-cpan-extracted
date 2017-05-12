use strict;
use warnings;
use Test::Is qw/extended/;
use Test::More tests => 10;

use WWW::Pastebin::Sprunge::Retrieve;
my $paster = WWW::Pastebin::Sprunge::Retrieve->new( timeout => 1 );

my $ID = 'WUSL';
my $CONTENT = "ohaithar\n";

SKIP: {
    my $ret = $paster->retrieve($ID) or do {
        diag "Got error on ->retrieve($ID): " . $paster->error;
        skip 'Got error', 10;
    };

    SKIP: {
        my $ret2 = $paster->retrieve("http://sprunge.us/$ID") or do {
            diag "Got error on ->retrieve('http://sprunge.us/$ID'): " . $paster->error;
            skip 'Got error', 1;
        };
        is_deeply(
            $ret,
            $ret2,
            'calls with ID and URI must return the same'
        );
    }
    SKIP: {
        my $ret3 = $paster->retrieve("http://sprunge.us/$ID?txt") or do {
            diag "Got error on ->retrieve('http://sprunge.us/$ID?txt'): " . $paster->error();
            skip "Got error", 1;
        };
        is_deeply(
            $ret,
            $ret3,
            'calls with a format parameter must return the same'
        );
    }

    is_deeply(
        $ret,
        $CONTENT,
        q{dump from Dumper must match ->retrieve()'s response},
    );

    is_deeply(
        $ret,
        $paster->results(),
        '->results() must now return whatever ->retrieve() returned',
    );

    is(
        $paster->id(),
        $ID,
        'paste ID must match the return from ->id()',
    );

    isa_ok( $paster->uri(), 'URI::http', '->uri() method' );

    is(
        $paster->uri(),
        "http://sprunge.us/$ID",
        'uri() must contain a URI to the paste',
    );

    isa_ok( $paster->ua(), 'LWP::UserAgent', '->ua() method' );

    is( "$paster", $ret, 'overloads');

    is( $paster->content(), $ret, 'content()');
}
