use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/Cryptsy.pm',
    't/00-compile.t',
    't/00-load.t',
    't/02-module-methods.t',
    't/API/authenticated/00-can.t',
    't/API/authenticated/01-getinfo.t',
    't/API/authenticated/02-getmarkets.t',
    't/API/authenticated/03-mytransactions.t',
    't/API/authenticated/04-markettrades.t',
    't/API/authenticated/05-marketorders.t',
    't/API/authenticated/06-mytrades.t',
    't/API/authenticated/07-allmytrades.t',
    't/API/authenticated/08-myorders.t',
    't/API/authenticated/09-depth.t',
    't/API/authenticated/10-allmyorders.t',
    't/API/authenticated/11-createorder.t',
    't/API/authenticated/12-cancelmarketorders.t',
    't/API/authenticated/13-cancelallorders.t',
    't/API/authenticated/14-calculatefees.t',
    't/API/authenticated/15-generatenewaddress.t',
    't/API/authenticated/KEYS',
    't/API/public/00-can.t',
    't/API/public/01-marketdata.t',
    't/API/public/02-marketdatav2.t',
    't/API/public/03-singlemarketdata.t',
    't/API/public/04-orderdata.t',
    't/API/public/05-singleorderdata.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
