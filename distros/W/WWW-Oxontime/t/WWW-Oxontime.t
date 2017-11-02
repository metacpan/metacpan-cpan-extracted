#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet ('www.oxontime.com' => 80);

use Test::More tests => 2;
BEGIN { use_ok('WWW::Oxontime', 'stops_for_route') };

my @stops = stops_for_route 15957;
ok @stops > 1, 'route 15957 has at least two stops';
