use strict;
use warnings;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set the environment variable OHLOH_KEY to your api key to enable these tests
END_MSG

unless ( $ENV{TEST_OHLOH_PROJECT} ) {
    plan skip_all => "set TEST_OHLOH_PROJECT to enable these tests";
}

plan tests => 18;

my $ohloh = WWW::Ohloh::API->new( debug => 1, api_key => $ENV{OHLOH_KEY} );

my $af = $ohloh->get_activity_facts( $ENV{TEST_OHLOH_PROJECT} );

my $facts = $af->latest;

