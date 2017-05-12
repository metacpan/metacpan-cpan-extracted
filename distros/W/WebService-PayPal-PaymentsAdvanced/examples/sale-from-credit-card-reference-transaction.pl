#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use lib 't/lib';

use DDP;
use Util;

my $payments = Util::ppa();

my $txn_id = shift @ARGV;
my $amount = shift @ARGV;

die
    'usage: perl examples/sale-from-credit-card-reference-transaction.pl [transaction_id] [amount]'
    unless $txn_id && $amount;

my $response = $payments->sale_from_credit_card_reference_transaction(
    $txn_id,
    $amount
);
p( $response->params );
