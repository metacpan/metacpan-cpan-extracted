#!/usr/bin/perl
use strict;
use warnings;
use Test::Most;

use lib "./lib";
use Weather::PurpleAir::API;

my $api_or = eval { Weather::PurpleAir::API->new(); };
ok defined $api_or, "new: not throwing exceptions";
is ref $api_or, "Weather::PurpleAir::API", "new: returned instantiation";

done_testing();
exit(0);
