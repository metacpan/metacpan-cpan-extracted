#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1;
use Wikibase::Datatype::Print::Snak;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1->new;

# Print out.
print scalar Wikibase::Datatype::Print::Snak::print($obj);

# Output:
# P854: https://skim.cz