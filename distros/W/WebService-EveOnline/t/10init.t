#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => 4;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

use_ok( 'WebService::EveOnline' );

ok( WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } ) );

my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );

is( $eve->user_id, $USER_ID, "is it the right user id?");
is( $eve->api_key, $API_KEY, "is it the right api key?");

