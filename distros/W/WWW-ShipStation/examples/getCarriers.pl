#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::ShipStation;
use Data::Dumper;

die "Please set ENV SHIPSTATION_USER and SHIPSTATION_PASS"
    unless $ENV{SHIPSTATION_USER} and $ENV{SHIPSTATION_PASS};

my $ws = WWW::ShipStation->new(
    user => $ENV{SHIPSTATION_USER},
    pass => $ENV{SHIPSTATION_PASS}
);

my $carriers = $ws->getCarriers();
print Dumper(\$carriers);

1;