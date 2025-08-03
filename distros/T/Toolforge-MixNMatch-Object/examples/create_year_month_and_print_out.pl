#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Object::YearMonth;

# Object.
my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
        'count' => 6,
        'month' => 1,
        'year' => 2020,
);

# Get count for year/month statistics.
my $count = $obj->count;

# Get month of statistics.
my $month = $obj->month;

# Get year of statistics.
my $year = $obj->year;

# Print out.
print "Count: $count\n";
print "Month: $month\n";
print "Year: $year\n";

# Output:
# Count: 6
# Month: 1
# Year: 2020