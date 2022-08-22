#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Human;
use Wikibase::Datatype::Print::Value::Item;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Human->new;

# Print out.
print scalar Wikibase::Datatype::Print::Value::Item::print($obj);

# Output:
# Q5