#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P5185: Q499327 (normal)
# References:
#   {
#     P248: Q53919
#     P214: 113230702
#     P813: 7 December 2013 (Q1985727)
#   }