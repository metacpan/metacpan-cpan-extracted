#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

my $can_trans = $ENV{EVE_TEST_TRANS} || undef;

SKIP: {
    skip "Please set environment variables EVE_API_KEY and EVE_USER_ID and EVE_TRANS_TEST to run tests", 1 unless $USER_ID != 1000000;
    skip "Testing transactions will prevent you from accessing your transactions via the API for 1 hour. Please set EVE_TRANS_TEST env var to proceed. ", 1 unless $can_trans;
    
    my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );

    ok( 1 );
};
