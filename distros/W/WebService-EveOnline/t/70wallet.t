#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

my $can_wallet = undef;

SKIP: {
    skip "Please set environment variables EVE_API_KEY and EVE_USER_ID to run tests", 8 unless $USER_ID != 1000000;
    
    my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );
    my @c = $eve->characters;

    skip "Bad details or server response", 8 unless $c[0]->id;

    is( ref($c[0]), 'WebService::EveOnline::API::Character', 'Returns a WebService::EveOnline::API::Character object?' );
    like( $c[0]->id, qr/\d+/, 'Looks like a character id?' );
    
    my @a = $c[0]->accounts;
    
    foreach my $a (@a) {
        like( $a[0]->balance, qr/\d+/, 'Looks like an account balance?' );
        like( $a[0]->type, qr/personal|corporate/, 'Looks like a valid account type?' );
        like( $a[0]->division, qr/first|second|third|fourth|fifth|sixth|seventh/, 'Looks like a valid division?' );
    } 
    
};
