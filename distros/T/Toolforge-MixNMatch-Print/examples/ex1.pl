#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Print::YearMonth;

# Object.
my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
        'count' => 6,
        'month' => 9,
        'year' => 2020,
);

# Print.
print Toolforge::MixNMatch::Print::YearMonth::print($obj)."\n";

# Output:
# 2020/9: 6