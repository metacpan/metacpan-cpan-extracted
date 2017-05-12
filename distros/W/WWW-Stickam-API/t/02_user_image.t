use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;

my $api = WWW::Stickam::API->new();
my $username = 'stickam';
#TEST OK
{
    if( $api->call('User/Image' , { user_name => $username } ) ) {
        ok( exists $api->get()->{media} ) ;
    } else {
        fail('user name test');
    }
}

# TEST NG
{
    if( $api->call('User/Image' , { user_name => ' ng n g ng gn ngn ngn ngnn gnn gn'} ) ) {
        fail('not found test');
    } else {
        pass('not found test');
        like( $api->error ,qr/^I guess / , 'error message test' );
    }
}

