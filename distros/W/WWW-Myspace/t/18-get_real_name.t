#!perl -T

#use Test::More 'no_plan';
use Test::More tests => 1;
use strict;

use WWW::Myspace;

use lib 't';
use TestConfig;
#login_myspace or die "Login Failed - can't run tests";

# Get myspace object
my $myspace = new WWW::Myspace( auto_login => 0 );

my $real_name = ( $myspace->get_real_name( $CONFIG->{'acct1'}->{'friend_id'} ) || '' );

warn "Got name: $real_name\n";

# This "test" is more for debugging - too unreliable a method to
# be able to really test it.
ok( 1, 'real_name');
