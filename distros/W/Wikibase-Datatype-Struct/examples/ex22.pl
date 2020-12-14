#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::String qw(struct2obj);

# String structure.
my $struct_hr = {
        'type' => 'string',
        'value' => 'foo',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get type.
my $type = $obj->type;

# Get value.
my $value = $obj->value;

# Print out.
print "Type: $type\n";
print "Value: $value\n";

# Output:
# Type: string
# Value: foo