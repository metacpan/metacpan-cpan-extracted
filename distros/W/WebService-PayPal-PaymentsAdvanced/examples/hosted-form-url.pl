#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use lib 't/lib';
use Util;

my $payments = Util::ppa();

my $response = $payments->create_secure_token(
    {
        AMT            => 100,
        TRXTYPE        => 'S',
        VERBOSITY      => 'HIGH',
        BILLINGTYPE    => 'MerchantInitiatedBilling',
        CANCELURL      => 'https://example.com/cancel',
        ERRORURL       => 'https://example.com/error',
        L_BILLINGTYPE0 => 'MerchantInitiatedBilling',
        NAME           => 'Chuck Norris',
        RETURNURL      => 'https://example.com/return',
    }
);

say $response->hosted_form_uri || die;
