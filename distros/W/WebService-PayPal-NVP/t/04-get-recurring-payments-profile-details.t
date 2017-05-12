use strict;
use warnings;

use Test::More;
use YAML::Syck;
use WebService::PayPal::NVP;

SKIP: {
    # we only want to run tests if auth exists
    # can't really say the tests fail if the auth file is missing (user error)
    # so let's just skip it and alert them why
    unless ( -f 'auth.yml' ) {
        skip 'auth.yml file missing with PayPal API credentials', 2;
    }

    my $config = LoadFile('auth.yml');
    my $nvp    = WebService::PayPal::NVP->new(
        api_ver => 95,
        branch  => $config->{branch},
        pwd     => $config->{pass},
        sig     => $config->{sig},
        user    => $config->{user},
    );

    my $res = $nvp->get_recurring_payments_profile_details(
        { profileid => 'foo' } );

    ok !$res->success, 'We know this will fail';
    ok(
        (
                   $res->errors->[0] eq 'The profile ID is invalid'
                || $res->errors->[0] eq
                'Subscription Profiles not supported by Recurring Payment APIs'
        ),
        'error message'
    );
}

done_testing();
