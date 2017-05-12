use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set OHLOH_KEY to your api key to enable these tests
END_MSG

unless ( $ENV{TEST_OHLOH_ACCOUNT} =~ /(id|email):(.+)/ ) {
    plan skip_all =>
      "set TEST_OHLOH_ACCOUNT to 'id:accountid' or 'email:addie' "
      . "to enable these tests";
}

plan 'no_plan';

require 't/Validators.pm';

my $ohloh = WWW::Ohloh::API->new( debug => 1, api_key => $ENV{OHLOH_KEY} );

diag "using account $ENV{TEST_OHLOH_ACCOUNT}";

$ENV{TEST_OHLOH_ACCOUNT} =~ s/(id|email)://;

my $stack = $ohloh->get_account_stack( $ENV{TEST_OHLOH_ACCOUNT} );

validate_stack($stack);

