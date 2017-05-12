use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;
use Data::Dumper;

my $api = WWW::Stickam::API->new();
my $username = 'stickam';
#TEST OK
{
    if( $api->call('User/Video' , { user_name => $username } ) ) {
        ok( $api->get()->{media}[0]{media_id} ) ;
    } else {
        fail('user name test');
    }
}

# TEST NG
{
    if( $api->call('User/Video' , { user_name=> ' ng n g ng gn ngn ngn ngnn gnn gn' } ) ) {
        fail('not found test');
    } else {
        pass('not found test');
        like( $api->error ,qr/^I guess / , 'error message test' );
    }
}

