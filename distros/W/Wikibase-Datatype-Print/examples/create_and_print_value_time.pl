#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Time;
use Wikibase::Datatype::Value::Time;

# Object.
my $obj = Wikibase::Datatype::Value::Time->new(
        'precision' => 11,
        'value' => '+2020-09-01T00:00:00Z',
);

# Print.
print Wikibase::Datatype::Print::Value::Time::print($obj)."\n";

# Output:
# 1 September 2020 (Q1985727)