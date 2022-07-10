#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Property;

# Object.
my $obj = Wikibase::Datatype::Value::Property->new(
        'value' => 'P123',
);

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