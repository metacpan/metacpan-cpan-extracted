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
        skip "auth.yml file missing with PayPal API credentials", 8;
    }

    # check config
    my $config = LoadFile("auth.yml");
    ok $config->{user},   "Username exists in config";
    ok $config->{pass},   "Password exists in config";
    ok $config->{sig},    "Signature exists in config";
    ok $config->{branch}, "Branch exists in config";

    my $nvp = WebService::PayPal::NVP->new(
        branch => $config->{branch},
        user   => $config->{user},
        pwd    => $config->{pass},
        sig    => $config->{sig},
    );

    ok( !$nvp->has_errors, 'no errors on connect' );

    is ref($nvp), 'WebService::PayPal::NVP',
        "Created WebService::PayPal::NVP instance";

    my $res = $nvp->set_express_checkout(
        {
            desc              => 'Payment for awesome stuff',
            amt               => 27.15,
            currencycode      => 'GBP',
            paymentaction     => 'Sale',
            returnurl         => "http://www.example.com/returnurl",
            cancelurl         => 'http://www.example.com/cancelurl',
            landingpage       => 'Login',
            addoverride       => 1,
            shiptoname        => "Coffee Drinker",
            shiptostreet      => "21 Jump Street",
            shiptostreet2     => "",
            shiptocity        => "City",
            shiptozip         => "T3ST4R 31",
            shiptoemail       => "test\@example.com",
            shiptocountrycode => 'GB',
        }
    );

    is ref($res), "WebService::PayPal::NVP::Response",
        "Method 'set_express_checkout' returned a WebService::PayPal::NVP::Response object";

    ok $res->success, "Response was successful";
    warn $_ for @{ $res->errors };
    ok $res->token, "Received a valid token (" . $res->token . ")";
    ok( !$res->has_errors, 'no errors' );
    diag "errors: " . $res->has_errors;
}

done_testing();
