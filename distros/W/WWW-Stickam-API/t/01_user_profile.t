use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'lib';
use WWW::Stickam::API;

my $api = WWW::Stickam::API->new();
my $username = 'stickam';
#TEST OK
{
    if( $api->call('User/Profile' , { user_name => $username } ) ) {
        is( $api->get()->{user_name}, $username ) ;
    } else {
        fail('user name test');
    }
}

# TEST NG
{
    if( $api->call('User/Profile' , { user_name => ' ng n g ng gn ngn ngn ngnn gnn gn'} ) ) {
        fail('not found test');
    } else {
        pass('not found test');
        like( $api->error ,qr/^I guess / , 'error message test' );
    }
}

