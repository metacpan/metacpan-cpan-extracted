#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Time;

# Object.
my $obj = Wikibase::Datatype::Value::Time->new(
        'precision' => 10,
        'value' => '+2020-09-01T00:00:00Z',
);

# Get calendar model.
my $calendarmodel = $obj->calendarmodel;

# Get precision.
my $precision = $obj->precision;

# Get type.
my $type = $obj->type;

# Get value.
my $value = $obj->value;

# Print out.
print "Calendar model: $calendarmodel\n";
print "Precision: $precision\n";
print "Type: $type\n";
print "Value: $value\n";

# Output:
# Calendar model: Q1985727
# Precision: 10
# Type: time
# Value: +2020-09-01T00:00:00Z