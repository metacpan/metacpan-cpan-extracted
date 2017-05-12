#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use WebService::Cryptsy;
use lib qw(lib  ../lib);

my $cryp = WebService::Cryptsy->new(
    public_key => 'YOUR PUBLIC KEY',
    private_key => 'YOUR PRIVATE KEY',
);

my $market_data = $cryp->marketdatav2
    or die "Error fetching data: " . $cryp->error;

my $markets = $market_data->{markets};

printf "%s: %f\n", @{ $markets->{$_} }{qw/label  lasttradeprice/}
    for sort keys %$markets;

