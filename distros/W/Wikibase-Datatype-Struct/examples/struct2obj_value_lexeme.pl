#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Value::Lexeme qw(struct2obj);

# Item structure.
my $struct_hr = {
        'type' => 'wikibase-entityid',
        'value' => {
                'entity-type' => 'lexeme',
                'id' => 'L42284',
                'numberic-id' => 42284,
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
# Type: lexeme
# Value: L42284