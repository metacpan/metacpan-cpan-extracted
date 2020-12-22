#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Struct::YearMonth qw(struct2obj);

# Time structure.
my $struct_hr = {
       'cnt' => 6,
       'ym' => 202009,
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get count.
my $count = $obj->count;

# Get month.
my $month = $obj->month;

# Get year.
my $year = $obj->year;

# Print out.
print "Count: $count\n";
print "Month: $month\n";
print "Year: $year\n";

# Output:
# Count: 6
# Month: 9
# Year: 2020