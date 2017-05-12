#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;


SKIP: {
	skip "Please set EVE_USER_ID and EVE_API_KEY environment variables to enable this test", 8 if $USER_ID == 1000000;
	
	my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );
	my @c = $eve->characters;
	
	skip "Bad details or server response", 8 unless $c[0]->id;
	
    is( ref($c[0]), 'WebService::EveOnline::API::Character', 'Returns a WebService::EveOnline::API::Character object?' );
    like( $c[0]->id, qr/\d+/, 'Looks like a character id?' );
    like( $c[0]->account->balance, qr/\d+/, 'Looks like an account balance?' );
    like( $c[0]->race, qr/\w+/, 'Looks like a race?' );
    like( $c[0]->gender, qr/\w+/, 'Looks like a gender?' );
    like( $c[0]->bloodline, qr/\w+/, 'Looks like a bloodline?' );
    like( $c[0]->attributes->memory, qr/\d+/, 'Looks like an attribute?' );
    
    my @s = $c[0]->skills;
    like( $s[0]->id, qr/\d+/, 'Looks like a skill?' );

    # this test fails if the current selected character has no skill currently training.
    # as such it is currently disabled.
    if ($c[0]->skill->in_training) {
        like( $c[0]->skill->in_training->id, qr/\d+/, 'Looks like a skill in training?' );
    }
};
