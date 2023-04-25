#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Snak qw(struct2obj);

# Item structure.
my $struct_hr = {
        'datatype' => 'wikibase-item',
        'datavalue' => {
                'type' => 'wikibase-entityid',
                'value' => {
                        'entity-type' => 'item',
                        'id' => 'Q5',
                        'numeric-id' => 5,
                },
        },
        'property' => 'P31',
        'snaktype' => 'value',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get value.
my $datavalue = $obj->datavalue->value;

# Get datatype.
my $datatype = $obj->datatype;

# Get property.
my $property = $obj->property;

# Print out.
print "Property: $property\n";
print "Type: $datatype\n";
print "Value: $datavalue\n";

# Output:
# Property: P31
# Type: wikibase-item
# Value: Q5