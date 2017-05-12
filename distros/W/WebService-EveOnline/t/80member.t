#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

my $can_member = undef;

SKIP: {
    skip "Member API currently unimplemented", 1 unless $can_member;
    ok( 1 );
};
