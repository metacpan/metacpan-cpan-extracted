use strict;
use warnings;
use Test::More tests => 2;
use Test::PPPort;

do {
    no warnings 'redefine';
    local *Test::Builder::skip_all = sub {
        ok(1, 'skip_all: ' . $_[1]);
        like($_[1], qr/No such ppport.h file/, 'message');
    };
    local *Test::Builder::plan = sub {
        ok(0, 'why called plan method?');
    };

    ppport_ok;
};
