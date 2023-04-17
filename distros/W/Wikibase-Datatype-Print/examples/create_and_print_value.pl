#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::Value::Item->new(
        'value' => 'Q123',
);

# Print.
print Wikibase::Datatype::Print::Value::print($obj)."\n";

# Output:
# Q123