#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

# use lib 'lib';

use WebService::CoinSpot;

my $coinspot = WebService::CoinSpot->new(
 auth_key => 'xxxx',
 auth_secret => 'yyyy',
);

my $prices = $coinspot->latest();
p $prices;

my $orders = $coinspot->orders( cointype => 'BTC' );
p $orders;

my $ordersh = $coinspot->orders_history( cointype => 'ETC' );
p $ordersh;



# p $sys->mounts;
