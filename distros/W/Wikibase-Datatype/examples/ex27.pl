#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::Snak->new(
        'datatype' => 'wikibase-item',
        'datavalue' => Wikibase::Datatype::Value::Item->new(
                'value' => 'Q5',
        ),
        'property' => 'P31',
);

# Get value.
my $datavalue = $obj->datavalue->value;

# Get datatype.
my $datatype = $obj->datatype;

# Get property.
my $property = $obj->property;

# Get snak type.
my $snaktype = $obj->snaktype;

# Print out.
print "Property: $property\n";
print "Type: $datatype\n";
print "Value: $datavalue\n";
print "Snak type: $snaktype\n";

# Output:
# Property: P31
# Type: wikibase-item
# Value: Q5
# Snak type: value