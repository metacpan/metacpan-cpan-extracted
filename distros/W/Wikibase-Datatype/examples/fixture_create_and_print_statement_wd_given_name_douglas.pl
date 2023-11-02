#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Michal;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Michal->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P735: Q18563993 (normal)