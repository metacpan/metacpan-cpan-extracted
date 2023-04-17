#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;
use Wikibase::Datatype::Print::Reference;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF->new;

# Print out.
print scalar Wikibase::Datatype::Print::Reference::print($obj);

# Output:
# {
#   P248: Q53919
#   P214: 113230702
#   P813: 07 December 2013 (Q1985727)
# }