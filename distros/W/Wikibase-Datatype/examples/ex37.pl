#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Quantity;

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
        'unit' => 'Q190900',
        'value' => '10',
);

# Get type.
my $type = $obj->type;

# Get unit.
my $unit = $obj->unit;

# Get value.
my $value = $obj->value;

# Print out.
print "Type: $type\n";
print "Unit: $unit\n";
print "Value: $value\n";

# Output:
# Type: quantity
# Unit: Q190900
# Value: 10