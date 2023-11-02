#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Lexeme;

# Object.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
        'value' => 'L42284',
);

# Get value.
my $value = $obj->value;

# Get type.
my $type = $obj->type;

# Print out.
print "Type: $type\n";
print "Value: $value\n";

# Output:
# Type: item
# Value: L42284