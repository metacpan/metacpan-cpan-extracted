use strict;
use warnings;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set OHLOH_KEY to your api key to enable these tests
END_MSG

unless ( $ENV{TEST_OHLOH_PROJECT} ) {
    plan skip_all => "set TEST_OHLOH_PROJECT to enable these tests";
}

plan 'no_plan';

my $ohloh = WWW::Ohloh::API->new( debug => 1, api_key => $ENV{OHLOH_KEY} );

diag "using project $ENV{TEST_OHLOH_PROJECT}";

my @factoids = $ohloh->get_factoids( $ENV{TEST_OHLOH_PROJECT} );

ok 1, "got factoids";

verify_factoid($_) for @factoids;

sub verify_factoid {
    my $f = shift;

    diag "doing new factoid";

    like $f->id          => qr/^\d+$/,        'id()';
    like $f->analysis_id => qr/^\d+$/,        'analysis_id()';
    like $f->type        => qr/^Factoid\w+$/, 'type()';
    ok $f->description, 'description()';
    like $f->severity => qr/^[+-]?[0123]$/, 'severity()';

    $f->license_id;
}

