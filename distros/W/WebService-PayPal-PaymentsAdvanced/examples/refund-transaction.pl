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

die 'usage: perl examples/void-transaction.pl ORIGID [AMT]'
    unless $txn_id;

my $response = $payments->refund_transaction(
    $txn_id,
    $amount ? ( AMT => $amount ) : (),
);
p( $response->params );
