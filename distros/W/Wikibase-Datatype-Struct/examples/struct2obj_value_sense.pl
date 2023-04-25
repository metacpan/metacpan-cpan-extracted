#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::Sense qw(struct2obj);

# Property structure.
my $struct_hr = {
        'type' => 'wikibase-entityid',
        'value' => {
                'entity-type' => 'sense',
                'id' => 'L34727-S1',
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
# Type: sense
# Value: L34727-S1