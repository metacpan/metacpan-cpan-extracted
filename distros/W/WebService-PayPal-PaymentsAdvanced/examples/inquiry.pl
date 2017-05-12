#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use lib 't/lib';

use DDP;
use Util;

my $payments = Util::ppa();

my $txn_id = shift @ARGV;

die 'usage: perl examples/inquiry.pl [transaction_id]'
    unless $txn_id;

my $response = $payments->inquiry_transaction($txn_id);
p( $response->params );
