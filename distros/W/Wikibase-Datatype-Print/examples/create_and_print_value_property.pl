#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Property;
use Wikibase::Datatype::Value::Property;

# Object.
my $obj = Wikibase::Datatype::Value::Property->new(
        'value' => 'P31',
);

# Print.
print Wikibase::Datatype::Print::Value::Property::print($obj)."\n";

# Output:
# P31