#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::MediainfoSnak qw(struct2obj);

# Item structure.
my $struct_hr = {
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

# Get property.
my $property = $obj->property;

# Get snak type.
my $snaktype = $obj->snaktype;

# Print out.
print "Property: $property\n";
print "Value: $datavalue\n";
print "Snak type: $snaktype\n";

# Output:
# Property: P31
# Value: Q5
# Snak type: value