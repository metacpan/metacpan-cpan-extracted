#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Item;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::Value::Item->new(
        'value' => 'Q123',
);

# Print.
print Wikibase::Datatype::Print::Value::Item::print($obj)."\n";

# Output:
# Q123