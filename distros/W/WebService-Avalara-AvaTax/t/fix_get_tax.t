#!/usr/bin/env perl

use strict;
use warnings;

use Const::Fast;
use Test::More;
use Test::File::ShareDir::Module 1.000000 {
    'WebService::Avalara::AvaTax::Service::Tax' => 'shares/ServiceTax/'
};
use Test::RequiresInternet ( 'development.avalara.net' => 443 );
use List::Util 1.33 'all';
use WebService::Avalara::AvaTax;

const my @AVALARA_ENV => qw(username password);

plan skip_all => 'set environment variables ' . join q{ } =>
    map {"AVALARA_\U$_"} @AVALARA_ENV
    if not all { $ENV{"AVALARA_\U$_"} } @AVALARA_ENV;
plan tests => 1;

my %get_tax_request = (
    CustomerCode    => 'test',
    CompanyCode     => 'zrinc',
    OriginCode      => 0,              # corresponds to AddressCode => 0 below
    DestinationCode => 1,              # corresponds to AddressCode => 1 below
    DocDate         => '2015-03-16',   # date on invoice, PO, etc. (required)
    Discount        => 0,
    DocType         => 'SalesInvoice',
    DetailLevel     => 'Tax',
    HashCode        => 0,
    Commit          => 'false',
    ServiceMode     => 'Automatic',
    PaymentDate     => '2015-03-16',
    ExchangeRate    => 1,
    ExchangeRateEffDate => '2015-03-16',
    Addresses           => {
        BaseAddress => [
            {   AddressCode => 0,
                Line1       => '1453 3rd St',
                Line2       => 'Suite 335',
                City        => 'Santa Monica',
                PostalCode  => '90401-3425',
                TaxRegionId => 0,
            },
            {   AddressCode => 1,
                Line1       => '401 Wilshire Blvd',
                Line2       => 'Suite 200',
                City        => 'Santa Monica',
                PostalCode  => '90401',
                TaxRegionId => 0,
            },
        ]
    },
    Lines => {
        Line => [
            {   No         => 1,
                ItemCode   => 'no-plan-trafficboost',
                Qty        => 1,
                Amount     => 95,
                Discounted => 'false',
                OriginCode => 0,
            },
            {   No         => 2,
                ItemCode   => 'np-plan-trafficboost',
                Qty        => 1,
                Amount     => 245,
                Discounted => 'false',
                OriginCode => 0,
            },
        ]
    },
);

my $avatax
    = WebService::Avalara::AvaTax->new( map { ( $_ => $ENV{"AVALARA_\U$_"} ) }
        @AVALARA_ENV );
my $answer_ref = $avatax->get_tax(%get_tax_request);
isa_ok( $answer_ref, 'HASH', 'hash reference answer' );
