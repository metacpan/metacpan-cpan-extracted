#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::Quantity qw(struct2obj);

# Quantity structure.
my $struct_hr = {
        'type' => 'quantity',
        'value' => {
                'amount' => '+10',
                'unit' => 'http://test.wikidata.org/entity/Q190900',
        },
};

# Get object.
my $obj = struct2obj($struct_hr);

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
# Unit: Q190900
# Value: 10