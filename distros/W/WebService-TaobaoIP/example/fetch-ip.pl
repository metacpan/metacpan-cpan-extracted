#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use lib '../lib';
use WebService::TaobaoIP;

my $ti = WebService::TaobaoIP->new('110.75.4.179');

say $ti->ip;
say $ti->country;
say $ti->area;
say $ti->region;
say $ti->city;
say $ti->isp;
