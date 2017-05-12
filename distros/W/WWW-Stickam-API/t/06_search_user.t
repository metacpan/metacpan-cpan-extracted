use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;
use Data::Dumper;

my $api = WWW::Stickam::API->new();
{
    if( $api->call('Search/User' , { name => 'stickam' } ) ) {
        ok( exists $api->get()->{user} ) ;
    } else {
        fail('media_id test');
    }
}

