use strict;
use warnings;

use Test::More;
use YAML::Syck;
use WebService::PayPal::NVP;

SKIP: {
    # we only want to run tests if auth exists
    # can't really say the tests fail if the auth file is missing (user error)
    # so let's just skip it and alert them why
    unless ( -f "auth.yml" ) {
        skip "auth.yml file missing with PayPal API credentials", 2;
    }

    my $config = LoadFile("auth.yml");
    my $nvp    = WebService::PayPal::NVP->new(
        branch => $config->{branch},
        user   => $config->{user},
        pwd    => $config->{pass},
        sig    => $config->{sig},
    );

    ok( !$nvp->has_errors, 'no errors on connect' );

    my $res = $nvp->manage_recurring_payments_profile_status(
        {
            profileid => 'foo',
            action    => 'cancel',
        }
    );

    ok !$res->success, 'We know this will fail';
    is( $res->errors->[0], 'The profile ID is invalid', 'error message' );
    ok( $res->has_errors, 'response has errors' );
}

done_testing();
