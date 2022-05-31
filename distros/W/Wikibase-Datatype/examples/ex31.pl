#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::String;

# Object.
my $obj = Wikibase::Datatype::Value::String->new(
        'value' => 'foo',
);

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