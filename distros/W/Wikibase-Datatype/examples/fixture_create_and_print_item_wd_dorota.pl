#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota;
use Wikibase::Datatype::Print::Item;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dorota->new;

# Print out.
print scalar Wikibase::Datatype::Print::Item::print($obj);

# Output:
# Label: Dorota (en)
# Description: female given name (en)
# Aliases:
#   Dorota (given name) (en)
#   Dorota (first name) (en)
# Statements:
#   P31: Q11879590 (normal)
#   References:
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }
#   P6254: L42284 (normal)
#   References:
#     {
#       P854: https://skim.cz
#       P813: 7 December 2013 (Q1985727)
#     }
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }