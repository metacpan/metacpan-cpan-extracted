#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;
use Wikibase::Datatype::Print::Reference;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL->new;

# Print out.
print scalar Wikibase::Datatype::Print::Reference::print($obj);

# Output:
# {
#   P854: https://skim.cz
#   P813: 07 December 2013 (Q1985727)
# }