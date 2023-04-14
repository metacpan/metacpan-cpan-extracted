#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::String;
use Wikibase::Datatype::Value::String;

# Object.
my $obj = Wikibase::Datatype::Value::String->new(
        'value' => 'foo',
);

# Print.
print Wikibase::Datatype::Print::Value::String::print($obj)."\n";

# Output:
# foo