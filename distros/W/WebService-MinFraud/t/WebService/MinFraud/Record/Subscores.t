use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Subscores;

my %subscores = (
    avs_result                               => 0.01,
    billing_address                          => 0.02,
    billing_address_distance_to_ip_location  => 0.03,
    browser                                  => 0.04,
    chargeback                               => 0.05,
    country                                  => 0.06,
    country_mismatch                         => 0.07,
    cvv_result                               => 0.08,
    email_address                            => 0.09,
    email_domain                             => 0.10,
    email_tenure                             => 0.11,
    ip_tenure                                => 0.12,
    issuer_id_number                         => 0.13,
    order_amount                             => 0.14,
    phone_number                             => 0.15,
    shipping_address_distance_to_ip_location => 0.16,
    time_of_day                              => 0.17,

);

my $model = WebService::MinFraud::Record::Subscores->new(%subscores);

for my $subscore ( sort keys %subscores ) {
    is( $model->$subscore, $subscores{$subscore}, $subscore );
}

done_testing;
