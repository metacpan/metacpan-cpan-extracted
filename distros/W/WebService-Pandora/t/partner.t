use strict;
use warnings;

use Test::More tests => 2;

use WebService::Pandora::Partner;

my $partner = WebService::Pandora::Partner->new( username => undef,
                                                 password => undef,
                                                 deviceModel => undef,
                                                 encryption_key => undef,
                                                 decryption_key => undef,
                                                 host => undef );

# test out not providing any of the required attributes
my $success = $partner->login();

ok( !$success, 'login error' );

is( $partner->error(),
    'The username, password, deviceModel, encryption_key, decryption_key, and host must all be provided to the constructor.',
    'login error string' );
