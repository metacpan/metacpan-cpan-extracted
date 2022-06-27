#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Quantity;

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
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
if (defined $unit) {
        print "Unit: $unit\n";
}
print "Value: $value\n";

# Output:
# Type: quantity
# Value: 10