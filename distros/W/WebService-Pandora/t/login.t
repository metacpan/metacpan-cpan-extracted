use strict;
use warnings;

use Test::More tests => 2;

use WebService::Pandora;

my $websvc = WebService::Pandora->new( username => undef,
                                       password => undef );

# test out not providing any username or password
my $success = $websvc->login();

ok( !$success, 'login failed' );
is( $websvc->error(), 'Both username and password must be given in the constructor.', 'login error string' );
