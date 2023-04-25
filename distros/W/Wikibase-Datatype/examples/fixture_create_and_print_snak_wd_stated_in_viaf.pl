#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF;
use Wikibase::Datatype::Print::Snak;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::StatedIn::VIAF->new;

# Print out.
print scalar Wikibase::Datatype::Print::Snak::print($obj);

# Output:
# P248: Q53919