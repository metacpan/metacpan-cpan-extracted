#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::Property qw(struct2obj);

# Property structure.
my $struct_hr = {
        'type' => 'wikibase-entityid',
        'value' => {
                'entity-type' => 'property',
                'id' => 'P123',
                'numeric-id' => 123,
        },
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get value.
my $value = $obj->value;

# Get type.
my $type = $obj->type;

# Print out.
print "Type: $type\n";
print "Value: $value\n";

# Output:
# Type: property
# Value: P123