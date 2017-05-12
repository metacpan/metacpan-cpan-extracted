#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use lib 't/lib';

use DDP;
use Util;

my $payments = Util::ppa();

die 'usage: perl examples/capture-paypal-transaction.pl baid 1.00 USD'
    unless scalar @ARGV == 3;

my $response = $payments->sale_from_paypal_reference_transaction(@ARGV);
p( $response->params );
