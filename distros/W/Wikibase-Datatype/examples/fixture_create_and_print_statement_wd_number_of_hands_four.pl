#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P123456789: 4 (normal)