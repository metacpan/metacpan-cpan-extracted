#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog;
use Wikibase::Datatype::Print::Snak;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog->new;

# Print out.
print scalar Wikibase::Datatype::Print::Snak::print($obj);

# Output:
# P5137: Q144