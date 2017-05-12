use strict;
use Test::More;
use lib '../lib';
use Box::Calc;
use 5.010;
use Ouch;

my $user_id  = $ENV{USPS_USERID};
my $password = $ENV{USPS_PASSWORD};

if (!$user_id || !$password) {
    plan skip_all => 'Missing USPS_USERID or USPS_PASSWORD';
}

use_ok 'USPS::RateRequest';

my $calc = Box::Calc->new();
$calc->add_box_type({
    x => 12,
    y => 12,
    z => 5.75,
    weight => 10,
    name => 'A',
});
$calc->add_item(1,
    x => 8,
    y => 8,
    z => 5.75,
    name => 'dense pumpkin',
    weight => 2000,
);
$calc->pack_items;

my $rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    postal_code => 97229,
    country     => 'United States of America',
);

my $rates = eval { $rate->request_rates($calc->boxes)->recv; };

ok hug(), 'Weight violation throws an exception: '. bleep();

$calc = Box::Calc->new();
$calc->add_box_type({
    x => 12,
    y => 12,
    z => 5.75,
    weight => 10,
    name => 'A',
});
$calc->add_item(1,
    x => 8,
    y => 8,
    z => 5.75,
    name => 'tiny pumpkin',
    weight => 10,
);
$calc->pack_items;

my $rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    postal_code => 99999,
    country     => 'United States of America',
);

$rates = eval { $rate->request_rates($calc->boxes)->recv; };

ok hug(), 'Imaginary zip codes throws an exception: '. bleep();

done_testing();

