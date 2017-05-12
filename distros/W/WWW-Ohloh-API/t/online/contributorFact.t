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

my $project = $ohloh->get_project( $ENV{TEST_OHLOH_PROJECT} );

my @contributors = $project->contributors;

ok 1, "got contributors";

verify_contributor($_) for @contributors;

sub verify_contributor {
    my $c = shift;

    diag "doing new contributor";

    like $c->primary_language_nice_name, qr/\w+/,
      "primary_language_nice_name";

}

