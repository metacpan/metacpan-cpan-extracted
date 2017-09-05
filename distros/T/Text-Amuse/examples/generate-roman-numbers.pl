#!/usr/bin/env perl

use strict;
use warnings;
use Roman;
use Data::Dumper::Concise;

my @nums;
foreach my $num (1..89) {
    push @nums, roman($num);

}
print Dumper(\@nums);

