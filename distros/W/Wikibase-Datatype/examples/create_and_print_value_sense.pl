#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Sense;

# Object.
my $obj = Wikibase::Datatype::Value::Sense->new(
        'value' => 'L34727-S1',
);

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