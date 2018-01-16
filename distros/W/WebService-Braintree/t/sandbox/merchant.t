# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper qw(sandbox);

plan skip_all => "merchant_gateway->create returns a 404";

my $gateway = WebService::Braintree->configuration->gateway;
subtest 'create' => sub {
    my $result = $gateway->merchant->create({
        email => 'name@email.com',
        country_code_alpha => 'USA',
        payment_methods => [qw( credit_card paypal )],
    });
    validate_result($result) or return;

    my $merchant = $result->{merchant};
    cmp_ok($merchant->id, '!=', undef);
    is($merchant->email, 'name@email.com');
    is($merchant->company_name, 'name@email.com');
    is($merchant->country_code_alpha3, 'USA');
    is($merchant->country_code_alpha2, 'US');
    is($merchant->country_code_numeric, '840');
    is($merchant->country_name, 'United States of America');

    my $creds = $result->{credentials};
    cmp_ok($creds->access_token, '!=', undef);
    cmp_ok($creds->refresh_token, '!=', undef);
    cmp_ok($creds->expires_at, '!=', undef);
    is($creds->token_type, 'bearer');
};
