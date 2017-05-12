use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;
use Data::Dumper;

my $api = WWW::Stickam::API->new();
my $media_id = '174705167';
#TEST OK
{
    if( $api->call('Media/Information' , { media_id => $media_id } ) ) {
        ok( exists $api->get()->{media_id} ) ;
    } else {
        fail('media_id test');
    }
}

# TEST NG
{
    if( $api->call('Media/Information' , { media_id => '01' } ) ) {
        fail('not found test');
    } else {
        pass('not found test');
        like( $api->error ,qr/^I guess / , 'error message test' );
    }
}

