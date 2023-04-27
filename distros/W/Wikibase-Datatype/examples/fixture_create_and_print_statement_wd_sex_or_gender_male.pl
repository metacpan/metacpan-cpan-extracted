#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P21: Q6581097 (normal)
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