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

# These tests (per the Ruby SDK) require creating a new merchant for each
# subtest. Since merchant_gateway->create doesn't work, these tests cannot
# be written.

plan skip_all => "Tests require merchant_gateway->create which returns 404";
