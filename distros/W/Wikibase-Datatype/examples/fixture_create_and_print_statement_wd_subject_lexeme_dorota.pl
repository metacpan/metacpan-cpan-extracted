#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SubjectLexeme::Dorota;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SubjectLexeme::Dorota->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P6254: L42284 (normal)
# References:
#   {
#     P854: https://skim.cz
#     P813: 7 December 2013 (Q1985727)
#   }
#   {
#     P248: Q53919
#     P214: 113230702
#     P813: 7 December 2013 (Q1985727)
#   }