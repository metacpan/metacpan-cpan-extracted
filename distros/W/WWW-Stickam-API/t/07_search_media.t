use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;
use Data::Dumper;

my $api = WWW::Stickam::API->new();
{
    if( $api->call('Search/Media' , { type=>'video' , text=> "Welcome to Stickam" } ) ) {
        ok( exists $api->get()->{num_results} ) ;
    } else {
        fail('media_id test');
    }
}

