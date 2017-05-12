use strict;
use Test::More;
use lib '../lib';
use Box::Calc;
use 5.010;

my $user_id  = $ENV{USPS_USERID};
my $password = $ENV{USPS_PASSWORD};

if (!$user_id || !$password) {
    plan skip_all => 'Missing USPS_USERID or USPS_PASSWORD';
}

use_ok 'USPS::RateRequest';

my $calc = Box::Calc->new();
$calc->add_box_type({
    x => 1,
    y => 1,
    z => 1,
    weight => 10,
    name => 'A',
});
$calc->add_item(1,
    x => 1,
    y => 1,
    z => 1,
    name => 'cube',
    weight => 1,
);
$calc->pack_items;

# Domestic
my $rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    postal_code => 90210,
    country     => 'United States of America',
    debug       => 1,
);
my $rates = $rate->request_rates($calc->boxes)->recv;


my $box = $calc->get_box(0)->id;
my %services = %{ $rates->{ $box } };

note "Domestic";
my @names = sort keys %services;
foreach my $name (@names) {
    note $name;
}
note "Domestic Translation Table";
foreach my $name (@names) {
    note $name . ' : ', $services{ $name }->{ label };
}

# International
$rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    country     => 'Australia',
    postal_code => '5068',
    debug       => 1,
);
$rates = $rate->request_rates($calc->boxes)->recv;

%services = %{$rates->{$calc->get_box(0)->id}};

note "International";
@names = sort keys %services;
foreach my $name (@names) {
    note $name;
}
note "International Translation Table";
foreach my $name (@names) {
    note $name . ' : ', $services{ $name }->{ label };
}

# DPO
$rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    country     => 'United States of America',
    postal_code => '09892',
    debug       => 1,
);
$rates = $rate->request_rates($calc->boxes)->recv;

%services = %{$rates->{$calc->get_box(0)->id}};

note "DPO";
@names = sort keys %services;
foreach my $name (@names) {
    note $name;
}
note "DPO Translation Table";
foreach my $name (@names) {
    note $name . ' : ', $services{ $name }->{ label };
}

# APO
$rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    country     => 'United States of America',
    postal_code => '96204-3027',
    debug       => 1,
);
$rates = $rate->request_rates($calc->boxes)->recv;

%services = %{$rates->{$calc->get_box(0)->id}};

note "APO";
@names = sort keys %services;
foreach my $name (@names) {
    note $name;
}
note "APO Translation Table";
foreach my $name (@names) {
    note $name . ' : ', $services{ $name }->{ label };
}

# FPO
$rate = USPS::RateRequest->new(
    user_id     => $user_id,
    password    => $password,
    from        => 53716,
    country     => 'United States of America',
    postal_code => '96677',
    debug       => 1,
);
$rates = $rate->request_rates($calc->boxes)->recv;

%services = %{$rates->{$calc->get_box(0)->id}};

note "FPO";
@names = sort keys %services;
foreach my $name (@names) {
    note $name;
}
note "FPO Translation Table";
foreach my $name (@names) {
    note $name . ' : ', $services{ $name }->{ label };
}

done_testing();

