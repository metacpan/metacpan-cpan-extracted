#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WebService::IPRental;
use Data::Dumper;

my $ipr = WebService::IPRental->new(
    APIkey   => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    APIpass  => 'xxxxxxxxxxxxxxxxx',
    Username => 'xxx@gmail.com',
    Password => 'xxx'
);

my $resp = $ipr->doIpLease();
print Dumper( \$resp );

1;
