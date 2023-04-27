#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::DouglasAdams;
use Wikibase::Datatype::Print::Item;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::DouglasAdams->new;

# Print out.
print scalar Wikibase::Datatype::Print::Item::print($obj);

# Output:
# Label: Douglas Adams (en)
# Description: English writer and humorist (1952-2001) (en)
# Aliases:
#   Douglas Noel Adams (en)
# Statements:
#   P31: Q5 (normal)
#   References:
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }
#   P21: Q6581097 (normal)
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
#   P735: Q463035 (normal)