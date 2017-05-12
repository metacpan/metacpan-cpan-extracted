use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

use WWW::Ohloh::API;

unless ( $ENV{TEST_OHLOH_PROJECT} ) {
    plan skip_all => "set TEST_OHLOH_PROJECT to a project id "
      . "to enable these tests";
}

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set the environment variable OHLOH_KEY to your api key to enable these tests
END_MSG

plan 'no_plan';

my $ohloh = WWW::Ohloh::API->new( api_key => $ENV{OHLOH_KEY}, debug => 1 );

my @sizeFacts = $ohloh->get_size_facts( $ENV{TEST_OHLOH_PROJECT} );

ok @sizeFacts > 1;

for my $sf (@sizeFacts) {

    isa_ok $sf, 'WWW::Ohloh::API::SizeFact';

    like $sf->month, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
    like $sf->$_, qr/^\d+$/ for qw/ code comments blanks commits man_months /;
    ok $sf->comment_ratio >= 0;
    ok $sf->comment_ratio <= 1;

    ok $sf->as_xml;
}

