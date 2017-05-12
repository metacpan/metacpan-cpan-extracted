use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;

my $api = WWW::Stickam::API->new();
my $username = 'stickam';

$api->call('User/Image' , { user_name => $username } );

ok( $api->tv_interval );
