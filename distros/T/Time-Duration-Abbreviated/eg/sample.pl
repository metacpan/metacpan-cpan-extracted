#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Time::Duration::Abbreviated;

print duration(12345, 2) . "\n";
print earlier(12345, 2) . "\n";
print later(12345, 2) . "\n";

print duration_exact(12345) . "\n";
print earlier_exact(12345) . "\n";
print later_exact(12345) . "\n";

