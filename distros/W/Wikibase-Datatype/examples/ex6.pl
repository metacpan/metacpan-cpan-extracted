#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams;
use Wikibase::Datatype::Print::Value::Item;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams->new;

# Print out.
print scalar Wikibase::Datatype::Print::Value::Item::print($obj);

# Output:
# Q42