#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::Item qw(struct2obj);

# Item structure.
my $struct_hr = {
        'type' => 'wikibase-entityid',
        'value' => {
                'entity-type' => 'item',
                'id' => 'Q123',
                'numberic-id' => 123,
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
# Type: item
# Value: Q123