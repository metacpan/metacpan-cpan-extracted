#!perl -T

use Test::More tests => 3; 
#use Test::More 'no_plan';
use lib 't';
use TestConfig;
use Data::Dumper;
use WWW::Myspace::MyBase;
#use WWW::Myspace::FriendAdder;

SKIP: {
    skip "test uses FriendAdder which has been moved", 3;
    # create an object without params
    my $adder = WWW::Myspace::FriendAdder->new();
    
    isa_ok($adder, 'WWW::Myspace::FriendAdder');
    my %config = (
        'config_file'        => 't/friend_adder.cfg', 
        'config_file_format' => 'CFG',
    );
    
    $adder = WWW::Myspace::FriendAdder->new( \%config );
    isa_ok($adder, 'WWW::Myspace::FriendAdder');
    
    login_myspace or die "Login Failed - can't run tests";
    
    # create valid myspqce object
    my $myspace = $CONFIG->{'acct1'}->{'myspace'};
    
    $adder = WWW::Myspace::FriendAdder->new( $myspace );
    isa_ok($adder, 'WWW::Myspace::FriendAdder');
}